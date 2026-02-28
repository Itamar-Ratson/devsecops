provider "kind" {}
provider "docker" {}

locals {
  globals = yamldecode(file("${var.helm_values_dir}/globals.yaml"))
  domain  = local.globals.cloudflare.domain
}

resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    networking {
      disable_default_cni = true
    }

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-PATCH
        kind: InitConfiguration
        nodeRegistration:
          taints:
            - key: "node-role.kubernetes.io/control-plane"
              effect: "NoSchedule"
        PATCH
      ]
    }

    node {
      role = "worker"
    }
  }
}

# Discover the KinD Docker network to get the subnet
data "docker_network" "kind" {
  name = "kind"

  depends_on = [kind_cluster.this]
}

# Connect Vault container to KinD network with a static IP
# The static IP is the .100 address on the KinD subnet
locals {
  # KinD network subnet looks like "172.X.0.0/16" — extract the first two octets
  kind_subnet       = [for s in data.docker_network.kind.ipam_config : s.subnet if can(regex("^172\\.", s.subnet))][0]
  kind_subnet_parts = split(".", local.kind_subnet)
  vault_cluster_ip  = "${local.kind_subnet_parts[0]}.${local.kind_subnet_parts[1]}.0.100"
  cache_cluster_ip  = "${local.kind_subnet_parts[0]}.${local.kind_subnet_parts[1]}.0.101"
  # First IP from the CiliumLoadBalancerIPPool (172.X.0.200/29) — must match lbPool.cidr
  # in helm/networking/gateway/values.yaml.
  gateway_lb_ip = "${local.kind_subnet_parts[0]}.${local.kind_subnet_parts[1]}.0.200"
}

resource "null_resource" "connect_vault_to_kind" {
  depends_on = [kind_cluster.this]

  triggers = {
    vault_container    = var.vault_container_name
    vault_container_id = var.vault_container_id
    cluster_name       = kind_cluster.this.name
    vault_ip           = local.vault_cluster_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Disconnect first if already connected (idempotent)
      docker network disconnect kind ${var.vault_container_name} 2>/dev/null || true
      # Connect with static IP
      docker network connect --ip ${local.vault_cluster_ip} kind ${var.vault_container_name}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "docker network disconnect kind ${self.triggers.vault_container} 2>/dev/null || true"
  }
}

resource "null_resource" "connect_cache_to_kind" {
  depends_on = [kind_cluster.this]

  triggers = {
    cache_container = var.cache_container_name
    cache_id        = var.cache_container_id
    cluster_name    = kind_cluster.this.name
    cache_ip        = local.cache_cluster_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      docker network disconnect kind ${var.cache_container_name} 2>/dev/null || true
      docker network connect --ip ${local.cache_cluster_ip} kind ${var.cache_container_name}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "docker network disconnect kind ${self.triggers.cache_container} 2>/dev/null || true"
  }
}

# Configure containerd on each KinD node to use Zot as a pull-through mirror.
# Zot runs as a plain registry (no on-demand sync), so uncached images get a
# fast 404 and containerd falls back to the upstream registry instantly.
# Run the registry/warm module after a successful apply to populate the cache.
resource "null_resource" "configure_registry_mirrors" {
  depends_on = [null_resource.connect_cache_to_kind]

  triggers = {
    cache_ip     = local.cache_cluster_ip
    cluster_name = kind_cluster.this.name
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      declare -A UPSTREAM=(
        [docker.io]="https://registry-1.docker.io"
        [ghcr.io]="https://ghcr.io"
        [quay.io]="https://quay.io"
        [registry.k8s.io]="https://registry.k8s.io"
      )
      for node in $(kind get nodes --name ${kind_cluster.this.name}); do
        for registry in "$${!UPSTREAM[@]}"; do
          docker exec "$node" mkdir -p "/etc/containerd/certs.d/$registry"
          docker exec "$node" sh -c "cat > /etc/containerd/certs.d/$registry/hosts.toml <<TOML
server = \"$${UPSTREAM[$registry]}\"

[host.\"http://${local.cache_cluster_ip}:5000\"]
  capabilities = [\"pull\", \"resolve\"]
TOML"
        done
      done
    EOT
  }
}

# Split-horizon DNS: resolve *.domain to the gateway LB IP on the host.
#
# Architecture — two-layer split:
#
#   PREREQUISITE (one-time, run manually with sudo before first deploy):
#     sudo ./scripts/setup-host-dns.sh
#
#   This tells systemd-resolved to forward all *.domain queries to the
#   local dnsmasq instance at 127.0.0.1:5353.  The file persists across
#   cluster recreations (correct: it's a machine-level setting).  When the
#   cluster is destroyed and dnsmasq stops, queries fall through to public DNS.
#
#   TERRAFORM (per-cluster, fully rootless):
#     Runs dnsmasq as a user-scope transient systemd service (systemd-run
#     --user, no sudo required) and stops it on destroy.
#
# Note: supports multiple gateways — add extra address= lines and
# additional CiliumLoadBalancerIPPools when a second Gateway is introduced.
resource "null_resource" "host_dns" {
  # Sequenced after connect_cache_to_kind to guarantee the KinD bridge
  # interface (and thus the Docker bridge route) exists before we start
  # the DNS service (Docker creates the bridge when the first container
  # connects to the network).
  depends_on = [null_resource.connect_cache_to_kind]

  triggers = {
    gateway_lb_ip = local.gateway_lb_ip
    domain        = local.domain
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      # CI uses port-forward + localhost for tests — no split-horizon DNS needed.
      if [ "$${CI:-false}" = "true" ]; then
        echo "CI: skipping host DNS setup"
        exit 0
      fi

      # Preflight: verify the one-time DNS prerequisite is in place.
      if [ ! -f /etc/systemd/resolved.conf.d/kind-gateway.conf ]; then
        echo "ERROR: missing one-time DNS prerequisite." >&2
        echo "Run the following once (from the repo root), then re-apply:" >&2
        echo "" >&2
        echo "  sudo ./scripts/setup-host-dns.sh" >&2
        exit 1
      fi

      # Install dnsmasq-base (binary only, no system service) if missing.
      # This is the only command that may prompt for sudo; if dnsmasq is
      # already installed the check short-circuits and sudo is never called.
      command -v dnsmasq >/dev/null 2>&1 || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q dnsmasq-base

      # Stop any existing instance from a previous apply; reset-failed clears
      # the dead unit so systemd-run --unit can reuse the name immediately.
      systemctl --user stop kind-gateway-dns.service 2>/dev/null || true
      systemctl --user reset-failed kind-gateway-dns.service 2>/dev/null || true

      # Write dnsmasq config — add address= lines here for additional gateways
      cat > /tmp/kind-gateway-dnsmasq.conf <<EOF
port=5353
bind-interfaces
listen-address=127.0.0.1
%{for prefix in var.dns_passthrough_prefixes~}
server=/${prefix}${local.domain}/8.8.8.8
%{endfor~}
address=/.${local.domain}/${local.gateway_lb_ip}
no-resolv
no-hosts
EOF

      # Run as a user-scope transient systemd service (no sudo required).
      systemd-run --user --unit=kind-gateway-dns \
        --description="KinD gateway DNS (*.${local.domain} -> ${local.gateway_lb_ip})" \
        dnsmasq -k --conf-file=/tmp/kind-gateway-dnsmasq.conf
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = "systemctl --user stop kind-gateway-dns.service 2>/dev/null || true"
  }
}

# Get control plane internal IP for Vault K8s auth config
data "external" "control_plane_ip" {
  program = ["bash", "-c", <<-EOT
    IP=$(docker inspect ${var.cluster_name}-control-plane --format '{{.NetworkSettings.Networks.kind.IPAddress}}')
    echo "{\"ip\": \"$IP\"}"
  EOT
  ]

  depends_on = [kind_cluster.this]
}
