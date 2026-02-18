provider "kind" {}
provider "docker" {}

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

# Resolve *.onprem hostnames to the gateway LB IP on the host.
#
# dnsmasq runs on 127.0.0.1:5353 (no conflict with systemd-resolved on :53) and
# answers all *.onprem queries with gateway_lb_ip. resolvectl is configured to
# forward .onprem queries on the KinD bridge link to that dnsmasq instance —
# all other DNS queries are unaffected.
#
# The resolvectl config is per-link and transient: it is automatically cleared
# when the KinD bridge interface is removed on destroy, so no explicit cleanup
# is needed for it. Only the dnsmasq service needs to be stopped on destroy.
#
# Note: supports multiple *.onprem gateways — add extra address= lines and
# additional CiliumLoadBalancerIPPools when a second Gateway is introduced.
resource "null_resource" "host_dns" {
  # Sequenced after connect_cache_to_kind to guarantee the KinD bridge
  # interface exists before resolvectl tries to configure it (Docker creates
  # the bridge when the first container connects to the network).
  depends_on = [null_resource.connect_cache_to_kind]

  triggers = {
    gateway_lb_ip = local.gateway_lb_ip
    kind_subnet   = local.kind_subnet
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      # Install dnsmasq-base (binary only, no system service) if missing
      command -v dnsmasq >/dev/null 2>&1 || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q dnsmasq-base

      # Stop any existing instance from a previous apply; reset-failed clears
      # the dead unit so systemd-run --unit=kind-gateway-dns can reuse the name
      systemctl stop kind-gateway-dns.service 2>/dev/null || true
      systemctl reset-failed kind-gateway-dns.service 2>/dev/null || true

      # Write dnsmasq config — add address= lines here for additional gateways
      cat > /tmp/kind-gateway-dnsmasq.conf <<EOF
port=5353
bind-interfaces
listen-address=127.0.0.1
address=/.onprem/${local.gateway_lb_ip}
no-resolv
no-hosts
EOF

      # Run as a transient systemd service so it outlives this shell
      systemd-run --unit=kind-gateway-dns \
        --description="KinD gateway DNS (.onprem -> ${local.gateway_lb_ip})" \
        dnsmasq -k --conf-file=/tmp/kind-gateway-dnsmasq.conf

      # Forward .onprem queries on the KinD bridge link to our dnsmasq.
      # Use key-based parsing so field position changes don't silently produce
      # a wrong interface name.
      BRIDGE=$(ip -4 route show "${local.kind_subnet}" \
        | awk '/dev/ {for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}' \
        | head -1)
      if [ -z "$BRIDGE" ]; then
        echo "ERROR: could not find bridge interface for ${local.kind_subnet}" >&2
        exit 1
      fi
      resolvectl dns    "$BRIDGE" 127.0.0.1:5353
      resolvectl domain "$BRIDGE" ~onprem
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = "systemctl stop kind-gateway-dns.service 2>/dev/null || true"
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
