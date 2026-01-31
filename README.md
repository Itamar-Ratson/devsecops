# Kubernetes Local Dev Setup

A zero-trust Kubernetes development environment with comprehensive security and observability.

## Stack Overview

**Infrastructure**<br>
![KinD](https://img.shields.io/badge/KinD-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Cilium](https://img.shields.io/badge/Cilium-F8C517?style=flat&logo=cilium&logoColor=black)
![eBPF](https://img.shields.io/badge/eBPF-FF6600?style=flat&logo=ebpf&logoColor=white)
![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat&logo=envoyproxy&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=flat&logo=wireguard&logoColor=white)
![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)
![cert-manager](https://img.shields.io/badge/cert--manager-0A5CBF?style=flat&logo=letsencrypt&logoColor=white)
![Transit Vault](https://img.shields.io/badge/Transit_Vault-FFEC6E?style=flat&logo=vault&logoColor=black)

**Security & Identity**<br>
![Cilium Network Policies](https://img.shields.io/badge/Cilium_Network_Policies-F8C517?style=flat&logo=cilium&logoColor=black)
![Sealed Secrets](https://img.shields.io/badge/Sealed_Secrets-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Vault](https://img.shields.io/badge/Vault-FFEC6E?style=flat&logo=vault&logoColor=black)
![Vault Secrets Operator](https://img.shields.io/badge/Vault_Secrets_Operator-FFEC6E?style=flat&logo=vault&logoColor=black)
![Keycloak](https://img.shields.io/badge/Keycloak-4D4D4D?style=flat&logo=keycloak&logoColor=white)
![Tetragon](https://img.shields.io/badge/Tetragon-F8C517?style=flat&logo=cilium&logoColor=black)
![Kyverno](https://img.shields.io/badge/Kyverno-FF6F00?style=flat&logo=kubernetes&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat&logo=aquasecurity&logoColor=white)
![OWASP ZAP](https://img.shields.io/badge/OWASP_ZAP-00549E?style=flat&logo=owasp&logoColor=white)

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

## Prerequisites

![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![docker-compose](https://img.shields.io/badge/docker--compose-2496ED?style=flat&logo=docker&logoColor=white)
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
cp .env.example .env   # Configure secrets (see .env.example for details)
./setup.sh             # Creates cluster and deploys everything via GitOps
```

**What setup.sh does:** Creates Transit Vault, KinD cluster with Cilium, Sealed-Secrets, and ArgoCD. ArgoCD then deploys all remaining infrastructure via sync waves.

| Wave | Components |
|------|------------|
| 0 | ArgoCD (self-managed) |
| 1 | Tetragon, Kyverno, Trivy, cert-manager, Sealed-secrets, Strimzi, Network-policies |
| 2 | Kyverno-policies, Vault, Kafka |
| 3 | Vault-secrets-operator, Gateway, Kafka-UI, Argo-Rollouts |
| 4 | http-echo, juice-shop, Keycloak |
| 5 | Monitoring |

After setup, add the SSH key shown in output as a [deploy key](https://github.com/YOUR-ORG/devsecops/settings/keys) (read-only).

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Echo | https://echo.localhost | - |
| Juice Shop | https://juice-shop.localhost | - |
| Hubble UI | https://hubble.localhost | - |
| Grafana | https://grafana.localhost | SSO via Keycloak or .env: GRAFANA_ADMIN_* |
| Kafka UI | https://kafka-ui.localhost | - |
| ArgoCD | https://argocd.localhost | SSO via Keycloak or admin/.env: ARGOCD_ADMIN_PASSWORD_HASH |
| Vault UI | https://vault.localhost | SSO via Keycloak (OIDC) or root token below |
| Keycloak | https://keycloak.localhost | .env: KEYCLOAK_ADMIN_* |

**Vault root token:**
```bash
kubectl -n vault get secret vault-root-token -o jsonpath="{.data.token}" | base64 -d
```

## Alerting

Add to `.env` (all optional):
```bash
SLACK_CRITICAL_WEBHOOK=https://hooks.slack.com/...  # critical -> #alerts-critical + PagerDuty
SLACK_WARNING_WEBHOOK=https://hooks.slack.com/...   # warning -> #alerts-warning
PAGERDUTY_ROUTING_KEY=your-integration-key
```

## SSO with Keycloak

Add to `.env`:
```bash
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=admin
ARGOCD_OIDC_CLIENT_SECRET=$(openssl rand -hex 32)
GRAFANA_OIDC_CLIENT_SECRET=$(openssl rand -hex 32)
VAULT_OIDC_CLIENT_SECRET=$(openssl rand -hex 32)
```

Create users at https://keycloak.localhost (`devsecops` realm) and assign to groups:

| Group | ArgoCD | Grafana | Vault |
|-------|--------|---------|-------|
| admins | admin | Admin | default |
| developers | admin | Editor | default |
| viewers | readonly | Viewer | default |

## GitOps Workflow

**All changes go through Git** - edit `helm/<component>/values.yaml`, commit, push. ArgoCD syncs automatically.

```bash
# Never run helm/kubectl directly - let ArgoCD handle it
vim helm/vault/values.yaml && git add . && git commit -m "update" && git push
```

| Component | Deployed By |
|-----------|-------------|
| Cilium, Sealed-Secrets | setup.sh (re-run to change) |
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
./setup.sh  # Automatically cleans up and starts fresh

# Check network policies
kubectl get ciliumnetworkpolicies -A
hubble observe --namespace <namespace>

# Monitor ArgoCD sync
kubectl get applications -n argocd
```
