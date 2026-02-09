# DevSecOps - Kubernetes on Bare Metal VMs

A zero-trust Kubernetes development environment running on Talos Linux VMs with libvirt/KVM, managed by Terraform and Terragrunt.

## Stack Overview

**VM Infrastructure**<br>
![Talos Linux](https://img.shields.io/badge/Talos_Linux-FF7300?style=flat&logo=linux&logoColor=white)
![libvirt/KVM](https://img.shields.io/badge/libvirt%2FKVM-009639?style=flat&logo=linux&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![Terragrunt](https://img.shields.io/badge/Terragrunt-844FBA?style=flat&logo=terraform&logoColor=white)
![HCP Terraform](https://img.shields.io/badge/HCP_Terraform-844FBA?style=flat&logo=terraform&logoColor=white)

**Networking**<br>
![Cilium](https://img.shields.io/badge/Cilium-F8C517?style=flat&logo=cilium&logoColor=black)
![eBPF](https://img.shields.io/badge/eBPF-FF6600?style=flat&logo=ebpf&logoColor=white)
![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat&logo=envoyproxy&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=flat&logo=wireguard&logoColor=white)
![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Cilium Network Policies](https://img.shields.io/badge/Network_Policies-F8C517?style=flat&logo=cilium&logoColor=black)

**Security & Identity**<br>
![Vault](https://img.shields.io/badge/Vault-FFEC6E?style=flat&logo=vault&logoColor=black)
![cert-manager](https://img.shields.io/badge/cert--manager-0A5CBF?style=flat&logo=letsencrypt&logoColor=white)
![Keycloak](https://img.shields.io/badge/Keycloak-4D4D4D?style=flat&logo=keycloak&logoColor=white)
![kube-oidc-proxy](https://img.shields.io/badge/kube--oidc--proxy-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Tetragon](https://img.shields.io/badge/Tetragon-F8C517?style=flat&logo=cilium&logoColor=black)
![Kyverno](https://img.shields.io/badge/Kyverno-FF6F00?style=flat&logo=kubernetes&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat&logo=aquasecurity&logoColor=white)
![OWASP ZAP](https://img.shields.io/badge/OWASP_ZAP-00549E?style=flat&logo=owasp&logoColor=white)

**Dashboard**<br>
![Headlamp](https://img.shields.io/badge/Headlamp-2563EB?style=flat&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0id2hpdGUiPjxwYXRoIGQ9Ik05IDIxYzAgLjUuNCAxIDEgMWg0Yy42IDAgMS0uNSAxLTF2LTFIOXYxem0zLTE5QzggMiA1IDUgNSA5YzAgMi4zIDEuMSA0LjMgMyA1LjdWMTdjMCAuNi40IDEgMSAxaDZjLjYgMCAxLS40IDEtMXYtMi4zYzEuOS0xLjQgMy0zLjQgMy01LjcgMC00LTMuMS03LTctN3oiLz48L3N2Zz4=&logoColor=white)

**Observability**<br>
![Hubble](https://img.shields.io/badge/Hubble-F8C517?style=flat&logo=cilium&logoColor=black)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=flat&logo=prometheus&logoColor=white)
![PagerDuty](https://img.shields.io/badge/PagerDuty-06AC38?style=flat&logo=pagerduty&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/Loki-F46800?style=flat&logo=grafana&logoColor=white)
![Tempo](https://img.shields.io/badge/Tempo-F46800?style=flat&logo=grafana&logoColor=white)
![Alloy](https://img.shields.io/badge/Alloy-F46800?style=flat&logo=grafana&logoColor=white)
![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-000000?style=flat&logo=opentelemetry&logoColor=white)

**Messaging**<br>
![Kafka](https://img.shields.io/badge/Kafka-231F20?style=flat&logo=apachekafka&logoColor=white)
![Strimzi](https://img.shields.io/badge/Strimzi-191A1C?style=flat&logo=apachekafka&logoColor=white)

**GitOps & Delivery**<br>
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat&logo=argo&logoColor=white)
![Argo Rollouts](https://img.shields.io/badge/Argo_Rollouts-EF7B4D?style=flat&logo=argo&logoColor=white)

**CI/CD**<br>
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=githubactions&logoColor=white)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  libvirt/KVM Host                                       │
│                                                         │
│  ┌──────────────┐  ┌─────────────┐  ┌────────────────┐ │
│  │ Vault VM     │  │ CP Node     │  │ Worker Node    │ │
│  │ Ubuntu 24.04 │  │ Talos Linux │  │ Talos Linux    │ │
│  │ :8200        │  │ :6443       │  │                │ │
│  └──────┬───────┘  └──────┬──────┘  └───────┬────────┘ │
│         │                 │                  │          │
│         └─────────┬───────┴──────────────────┘          │
│              k8s-dev network (192.168.100.0/24)         │
└─────────────────────────────────────────────────────────┘
```

**Terraform modules** (deployed via Terragrunt):

| Order | Module | Description |
|-------|--------|-------------|
| 1 | `libvirt-network` | NAT network with static IPs |
| 2 | `vault-vm` | Vault server VM (transit + KV + K8s auth) |
| 3 | `talos-cluster` | Talos control plane + worker VMs |
| 4 | `cluster-config` | Cilium, Gateway API, cert-manager CA, Vault auth |
| 5 | `vault-config` | Vault secrets (OIDC, Grafana, Keycloak, ArgoCD) |
| 6 | `argocd-bootstrap` | ArgoCD Helm install + root Application |

## Prerequisites

![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Terraform](https://img.shields.io/badge/Terraform_≥1.10-844FBA?style=flat&logo=terraform&logoColor=white)
![Terragrunt](https://img.shields.io/badge/Terragrunt-844FBA?style=flat&logo=terraform&logoColor=white)
![libvirt/QEMU](https://img.shields.io/badge/libvirt%2FQEMU-009639?style=flat&logo=linux&logoColor=white)
![kubectl](https://img.shields.io/badge/kubectl-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)
![mkcert](https://img.shields.io/badge/mkcert-009639?style=flat&logo=letsencrypt&logoColor=white)

- **Terraform** >= 1.10 with HCP Terraform account
- **Terragrunt** for orchestrating module dependencies
- **libvirt/QEMU/KVM** with the default storage pool
- **kubectl**, **Helm**
- **mkcert** for local CA (cert-manager ClusterIssuer)

Increase inotify limits (required for monitoring stack):
```bash
# Temporary
sudo sysctl -w fs.inotify.max_user_instances=1024 fs.inotify.max_user_watches=16384

# Permanent: add to /etc/sysctl.conf
fs.inotify.max_user_instances=1024
fs.inotify.max_user_watches=16384
```

## Quick Setup

```bash
# 1. Configure secrets
cp terraform/live/dev/secrets.tfvars.example terraform/live/dev/secrets.tfvars
# Edit secrets.tfvars with your values

# 2. Deploy everything
cd terraform/live/dev
terragrunt run-all apply --terragrunt-non-interactive

# 3. Set execution mode for new workspaces (first run only)
# cluster-config, vault-config, argocd workspaces must be set to "local"
# execution mode in HCP Terraform (they access local VM IPs)
```

**What this does:** Creates a libvirt network, Vault VM, two Talos Linux VMs (control plane + worker), installs Cilium CNI, configures Vault secrets, and bootstraps ArgoCD. ArgoCD then deploys all remaining infrastructure via sync waves.

| Wave | Components |
|------|------------|
| 0 | ArgoCD (self-managed) |
| 1 | Tetragon, Kyverno, Trivy, cert-manager, Sealed-secrets, Strimzi, Network-policies |
| 2 | Kyverno-policies, Vault, Kafka |
| 3 | Vault-secrets-operator, Gateway, Kafka-UI, Argo-Rollouts |
| 4 | http-echo, juice-shop, Keycloak |
| 5 | Monitoring, kube-oidc-proxy, Headlamp |

## Destroy

```bash
cd terraform/live/dev
terragrunt run-all destroy --terragrunt-non-interactive
```

Destroy order is automatically reversed: argocd → vault-config → cluster-config → cluster → vault → network.

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Echo | https://echo.localhost | - |
| Juice Shop | https://juice-shop.localhost | - |
| Hubble UI | https://hubble.localhost | - |
| Headlamp | https://headlamp.localhost | SSO via Keycloak (testuser/testuser) |
| Grafana | https://grafana.localhost | SSO via Keycloak or secrets.tfvars |
| Kafka UI | https://kafka-ui.localhost | - |
| ArgoCD | https://argocd.localhost | SSO via Keycloak or secrets.tfvars |
| Vault UI | https://vault.localhost | SSO via Keycloak (OIDC) or root token |
| Keycloak | https://keycloak.localhost | secrets.tfvars |

## GitOps Workflow

**All changes go through Git** - edit `helm/<component>/values.yaml`, commit, push. ArgoCD syncs automatically.

```bash
# Never run helm/kubectl directly - let ArgoCD handle it
vim helm/vault/values.yaml && git add . && git commit -m "update" && git push
```

| Component | Deployed By |
|-----------|-------------|
| Network, Vault VM, Talos VMs, Cilium | Terraform/Terragrunt |
| Everything else | ArgoCD (commit to change) |

## Argo Rollouts

Canary deployments with Gateway API traffic splitting and Prometheus-based analysis.

**Apps:** http-echo, juice-shop

Update the image to trigger a rollout: 20% → 50% → 100% with automated analysis at each step.

```bash
kubectl argo rollouts promote http-echo -n http-echo  # promote immediately
kubectl argo rollouts abort http-echo -n http-echo    # rollback
```

## Troubleshooting

```bash
# Full reset
cd terraform/live/dev
terragrunt run-all destroy --terragrunt-non-interactive
terragrunt run-all apply --terragrunt-non-interactive

# Check VMs
virsh list --all
virsh vol-list --pool default

# Check network policies
kubectl get ciliumnetworkpolicies -A
hubble observe --namespace <namespace>

# Monitor ArgoCD sync
kubectl get applications -n argocd
```
