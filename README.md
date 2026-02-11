# Kubernetes Local Dev Setup

A zero-trust Kubernetes development environment with comprehensive security and observability.

## Stack Overview

**Infrastructure**<br>
![KinD](https://img.shields.io/badge/KinD-326CE5?style=flat&logo=kubernetes&logoColor=white)
![cert-manager](https://img.shields.io/badge/cert--manager-0A5CBF?style=flat&logo=letsencrypt&logoColor=white)
![trust-manager](https://img.shields.io/badge/trust--manager-0A5CBF?style=flat&logo=letsencrypt&logoColor=white)
![Transit Vault](https://img.shields.io/badge/Transit_Vault-FFEC6E?style=flat&logo=vault&logoColor=black)

**Networking**<br>
![Cilium](https://img.shields.io/badge/Cilium-F8C517?style=flat&logo=cilium&logoColor=black)
![eBPF](https://img.shields.io/badge/eBPF-FF6600?style=flat&logo=ebpf&logoColor=white)
![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat&logo=envoyproxy&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=flat&logo=wireguard&logoColor=white)
![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Cilium Network Policies](https://img.shields.io/badge/Network_Policies-F8C517?style=flat&logo=cilium&logoColor=black)

**Security & Identity**<br>
![Sealed Secrets](https://img.shields.io/badge/Sealed_Secrets-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Vault](https://img.shields.io/badge/Vault-FFEC6E?style=flat&logo=vault&logoColor=black)
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

**IaC & CI/CD**<br>
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![Terragrunt](https://img.shields.io/badge/Terragrunt-844FBA?style=flat&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=githubactions&logoColor=white)

## Prerequisites

![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![Terragrunt](https://img.shields.io/badge/Terragrunt-844FBA?style=flat&logo=terraform&logoColor=white)
![kubectl](https://img.shields.io/badge/kubectl-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)
![KinD](https://img.shields.io/badge/KinD-326CE5?style=flat&logo=kubernetes&logoColor=white)
![kubeseal](https://img.shields.io/badge/kubeseal-326CE5?style=flat&logo=kubernetes&logoColor=white)
![GitHub CLI](https://img.shields.io/badge/gh-181717?style=flat&logo=github&logoColor=white)

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
cp terraform/live/secrets.tfvars.example terraform/live/secrets.tfvars  # Configure secrets
cd terraform/live && terragrunt run-all apply --terragrunt-non-interactive
```

**What this does:** Creates Transit Vault (Docker container), KinD cluster with Cilium, installs CRDs, Sealed-Secrets, and bootstraps ArgoCD. ArgoCD then deploys all remaining infrastructure via sync waves.

| Wave | Components |
|------|------------|
| 0 | ArgoCD (self-managed) |
| 1 | Tetragon, Kyverno, Trivy, cert-manager, Sealed-secrets, Strimzi, Network-policies |
| 2 | Kyverno-policies, Vault, Kafka |
| 3 | Vault-secrets-operator, Gateway, Kafka-UI, Argo-Rollouts |
| 4 | http-echo, juice-shop, Keycloak |
| 5 | Monitoring, kube-oidc-proxy, Headlamp |

After setup, add the SSH deploy key as a [deploy key](https://github.com/YOUR-ORG/devsecops/settings/keys) (read-only).

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Echo | https://echo.localhost | - |
| Juice Shop | https://juice-shop.localhost | - |
| Hubble UI | https://hubble.localhost | - |
| Headlamp | https://headlamp.localhost | SSO via Keycloak (testuser/testuser) |
| Grafana | https://grafana.localhost | SSO via Keycloak or secrets.tfvars: grafana_admin |
| Kafka UI | https://kafka-ui.localhost | - |
| ArgoCD | https://argocd.localhost | SSO via Keycloak or admin/secrets.tfvars: argocd_admin |
| Vault UI | https://vault.localhost | SSO via Keycloak (OIDC) or root token below |
| Keycloak | https://keycloak.localhost | secrets.tfvars: keycloak_admin |

**Vault root token:**
```bash
kubectl -n vault get secret vault-root-token -o jsonpath="{.data.token}" | base64 -d
```

## Alerting

Add to `terraform/live/secrets.tfvars` (all optional):
```hcl
alertmanager_webhooks = {
  pagerduty_routing_key  = "your-integration-key"
  slack_critical_webhook = "https://hooks.slack.com/..."
  slack_warning_webhook  = "https://hooks.slack.com/..."
}
```

## SSO with Keycloak

Add to `terraform/live/secrets.tfvars`:
```hcl
oidc_client_secrets = {
  argocd   = "..."  # openssl rand -hex 32
  grafana  = "..."
  vault    = "..."
  headlamp = "..."
}
keycloak_admin = {
  username = "admin"
  password = "admin"
}
```

Create users at https://keycloak.localhost (`devsecops` realm) and assign to groups:

| Group | ArgoCD | Grafana | Vault | Headlamp |
|-------|--------|---------|-------|----------|
| admins | admin | Admin | default | cluster-admin |
| developers | admin | Editor | default | edit |
| viewers | readonly | Viewer | default | view |

## Headlamp Kubernetes Dashboard

Headlamp provides a web UI for Kubernetes with OIDC authentication via Keycloak.

**Architecture:**
```
Browser → Headlamp → kube-oidc-proxy → Kubernetes API
                ↓
            Keycloak (OIDC)
```

- **kube-oidc-proxy** validates OIDC tokens and impersonates users to the API server
- No API server OIDC configuration required (works with any K8s distribution)
- User permissions based on Keycloak group membership (RBAC)

**Test user:** `testuser` / `testuser` (member of `admins` group)

For implementation details, see [docs/HEADLAMP-OIDC-ISSUE.md](docs/HEADLAMP-OIDC-ISSUE.md).

## GitOps Workflow

**All changes go through Git** - edit `helm/<component>/values.yaml`, commit, push. ArgoCD syncs automatically.

```bash
# Never run helm/kubectl directly - let ArgoCD handle it
vim helm/vault/values.yaml && git add . && git commit -m "update" && git push
```

| Component | Deployed By |
|-----------|-------------|
| Transit Vault, KinD, Cilium, Sealed-Secrets, ArgoCD | Terraform/Terragrunt |
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
cd terraform/live && terragrunt run-all destroy --terragrunt-non-interactive
cd terraform/live && terragrunt run-all apply --terragrunt-non-interactive

# Check network policies
kubectl get ciliumnetworkpolicies -A
hubble observe --namespace <namespace>

# Monitor ArgoCD sync
kubectl get applications -n argocd
```
