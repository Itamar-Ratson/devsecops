# Kubernetes Local Dev Setup

A zero-trust Kubernetes development environment with comprehensive security and observability.

## Stack Overview

**Infrastructure**<br>
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![Terragrunt](https://img.shields.io/badge/Terragrunt-844FBA?style=flat&logo=terraform&logoColor=white)
![HCP Terraform](https://img.shields.io/badge/HCP_Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![KinD](https://img.shields.io/badge/KinD-326CE5?style=flat&logo=kubernetes&logoColor=white)
![cert-manager](https://img.shields.io/badge/cert--manager-0A5CBF?style=flat&logo=letsencrypt&logoColor=white)
![trust-manager](https://img.shields.io/badge/trust--manager-0A5CBF?style=flat&logo=letsencrypt&logoColor=white)
![Zot](https://img.shields.io/badge/Zot-4A154B?style=flat&logo=oci&logoColor=white)
![Let's Encrypt](https://img.shields.io/badge/Let's_Encrypt-003A70?style=flat&logo=letsencrypt&logoColor=white)

**Networking**<br>
![Cilium](https://img.shields.io/badge/Cilium-F8C517?style=flat&logo=cilium&logoColor=black)
![Envoy](https://img.shields.io/badge/Envoy-AC6199?style=flat&logo=envoyproxy&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=flat&logo=nginx&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=flat&logo=wireguard&logoColor=white)
![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Cilium Network Policies](https://img.shields.io/badge/Network_Policies-F8C517?style=flat&logo=cilium&logoColor=black)
![CoreDNS](https://img.shields.io/badge/CoreDNS-326CE5?style=flat&logo=kubernetes&logoColor=white)
![dnsmasq](https://img.shields.io/badge/dnsmasq-4A90D9?style=flat&logoColor=white)

**Security & Identity**<br>
![Tetragon](https://img.shields.io/badge/Tetragon-F8C517?style=flat&logo=cilium&logoColor=black)
![Kyverno](https://img.shields.io/badge/Kyverno-FF6F00?style=flat&logo=kubernetes&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat&logo=aquasecurity&logoColor=white)
![OWASP ZAP](https://img.shields.io/badge/OWASP_ZAP-00549E?style=flat&logo=owasp&logoColor=white)
![Vault](https://img.shields.io/badge/Vault-FFEC6E?style=flat&logo=vault&logoColor=black)
![Transit Vault](https://img.shields.io/badge/Transit_Vault-FFEC6E?style=flat&logo=vault&logoColor=black)
![Sealed Secrets](https://img.shields.io/badge/Sealed_Secrets-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Keycloak](https://img.shields.io/badge/Keycloak-4D4D4D?style=flat&logo=keycloak&logoColor=white)
![kube-oidc-proxy](https://img.shields.io/badge/kube--oidc--proxy-326CE5?style=flat&logo=kubernetes&logoColor=white)

**Observability**<br>
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/Loki-F46800?style=flat&logo=grafana&logoColor=white)
![Tempo](https://img.shields.io/badge/Tempo-F46800?style=flat&logo=grafana&logoColor=white)
![Alloy](https://img.shields.io/badge/Alloy-F46800?style=flat&logo=grafana&logoColor=white)
![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-000000?style=flat&logo=opentelemetry&logoColor=white)
![Hubble](https://img.shields.io/badge/Hubble-F8C517?style=flat&logo=cilium&logoColor=black)
![Headlamp](https://img.shields.io/badge/Headlamp-326CE5?style=flat&logo=kubernetes&logoColor=white)
![PagerDuty](https://img.shields.io/badge/PagerDuty-06AC38?style=flat&logo=pagerduty&logoColor=white)

**Messaging**<br>
![Kafka](https://img.shields.io/badge/Kafka-231F20?style=flat&logo=apachekafka&logoColor=white)
![Strimzi](https://img.shields.io/badge/Strimzi-191A1C?style=flat&logo=apachekafka&logoColor=white)

**AWS**<br>
![IAM](https://img.shields.io/badge/IAM-232F3E?style=flat&logo=amazoniam&logoColor=white)
![SSM Parameter Store](https://img.shields.io/badge/SSM_Parameter_Store-232F3E?style=flat&logo=amazonsystemsmanager&logoColor=white)
![KMS](https://img.shields.io/badge/KMS-232F3E?style=flat&logo=amazonwebservices&logoColor=white)

**Cloudflare**<br>
![Cloudflare Tunnel](https://img.shields.io/badge/Cloudflare_Tunnel-F38020?style=flat&logo=cloudflare&logoColor=white)
![Cloudflare Access](https://img.shields.io/badge/Cloudflare_Access-F38020?style=flat&logo=cloudflare&logoColor=white)

**GitOps & CI/CD**<br>
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat&logo=argo&logoColor=white)
![Argo Rollouts](https://img.shields.io/badge/Argo_Rollouts-EF7B4D?style=flat&logo=argo&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=githubactions&logoColor=white)
![Renovate](https://img.shields.io/badge/Renovate-1A1F6C?style=flat&logo=renovate&logoColor=white)
![cosign](https://img.shields.io/badge/cosign-7B2D8B?style=flat&logo=sigstore&logoColor=white)
![Syft](https://img.shields.io/badge/Syft-1D1D1D?style=flat&logo=anchore&logoColor=white)
![Gitleaks](https://img.shields.io/badge/Gitleaks-181717?style=flat&logo=git&logoColor=white)

## Prerequisites

![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![Terragrunt](https://img.shields.io/badge/Terragrunt-844FBA?style=flat&logo=terraform&logoColor=white)
![HCP Terraform](https://img.shields.io/badge/HCP_Terraform-844FBA?style=flat&logo=terraform&logoColor=white)
![kubectl](https://img.shields.io/badge/kubectl-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)
![KinD](https://img.shields.io/badge/KinD-326CE5?style=flat&logo=kubernetes&logoColor=white)
![kubeseal](https://img.shields.io/badge/kubeseal-326CE5?style=flat&logo=kubernetes&logoColor=white)
![GitHub CLI](https://img.shields.io/badge/gh-181717?style=flat&logo=github&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat&logo=aquasecurity&logoColor=white)
![Renovate](https://img.shields.io/badge/Renovate-1A1F6C?style=flat&logo=renovate&logoColor=white)

Increase inotify limits:

```bash
# Temporary
sudo sysctl -w fs.inotify.max_user_instances=1024 fs.inotify.max_user_watches=16384

# Permanent: add to /etc/sysctl.conf
fs.inotify.max_user_instances=1024
fs.inotify.max_user_watches=16384
```

Configure host DNS for `*.onprem` resolution (one-time, per machine):

```bash
sudo ./scripts/setup-host-dns.sh
```

This writes `/etc/systemd/resolved.conf.d/kind-gateway.conf` so that systemd-resolved
forwards `*.onprem` queries to the dnsmasq instance that Terraform starts on port 5353.
Run once before the first `terragrunt run --all apply`.

## Quick Setup

### Admin (one-time setup)

```bash
# 1. Configure AWS CLI with admin credentials
aws configure

# 2. Create IAM infrastructure (OIDC provider, CI role, team users)
cp terraform/live/aws/iam/team-members.csv.example terraform/live/aws/iam/team-members.csv
# Edit team-members.csv: add usernames for each team member
cd terraform/live/aws/iam && terragrunt apply --non-interactive

# 3. Seed SSM parameters from secrets.tfvars
cp terraform/live/secrets.tfvars.example terraform/live/secrets.tfvars  # fill in all values
cd ../ssm && terragrunt apply --non-interactive

# 4. Apply the full stack
cd ../../ && terragrunt run --all apply --non-interactive
```

After step 4, revoke the Vault root token:

```bash
vault login <vault_root_token>
vault token revoke -self
```

### Team members (day-to-day)

```bash
# 1. Configure AWS with the access key your admin provided
aws configure

# 2. Clone the repo and apply (no secrets files needed)
git clone git@github.com:itamar-ratson/devsecops.git
cd devsecops/terraform/live
terragrunt run --all apply --non-interactive
```

### Secrets Configuration

The admin fills in `terraform/live/secrets.tfvars` once to bootstrap SSM. After that, secrets
are managed in AWS SSM Parameter Store (free Standard tier). See `docs/runbooks/ssm-admin-guide.md`
for full admin procedures.

| Secret | How to Generate |
|--------|-----------------|
| `vault_root_token` | `openssl rand -base64 32` |
| `github_token` | GitHub token with `admin:repo_key` scope |
| `oidc_client_secrets` (argocd, grafana, vault, headlamp) | `openssl rand -hex 32` each |
| `keycloak_admin` | Choose username/password |
| `grafana_admin` | Choose username/password |
| `argocd_admin.password_hash` | `htpasswd -nbBC 10 "" 'your-password' \| tr -d ':\n'` |
| `argocd_admin.server_secret_key` | `openssl rand -base64 32` |
| `alertmanager_webhooks` (optional) | PagerDuty/Slack webhook URLs (or leave as `"DISABLED"`) |

| Wave | Role | Components |
|------|------|------------|
| 0 | Self-management | ArgoCD |
| 1 | Networking | Cilium (CNI + service mesh), Network-policies |
| 2 | Security: enforcement | Kyverno, Tetragon, Trivy |
| 3 | Security: policies | Kyverno-policies |
| 4 | Infrastructure foundations | cert-manager, VSO, Sealed-Secrets, Argo-Rollouts, Strimzi |
| 5 | Infrastructure services | trust-manager, Gateway, Kafka |
| 6 | Identity & secrets | Keycloak, Vault, Zot |
| 7 | OIDC proxy | kube-oidc-proxy |
| 8 | Observability | Monitoring, Kafka-UI, Headlamp |
| 9 | Demo apps | http-echo, juice-shop |

**Monitor Sync Waves:**

```bash
watch 'kubectl get pods -A --sort-by=.metadata.creationTimestamp --no-headers | tac | grep -v scan'
```

## Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Echo | <https://echo.onprem> | - |
| Juice Shop | <https://juice-shop.onprem> | - |
| Kafka UI | <https://kafka-ui.onprem> | - |
| Hubble UI | <https://hubble.onprem> | - |
| Zot Registry | <http://zot.onprem> | - |
| Headlamp | <https://headlamp.onprem> | SSO via Keycloak (testuser/testuser) |
| Grafana | <https://grafana.onprem> | SSO via Keycloak or secrets.tfvars: grafana_admin |
| ArgoCD | <https://argocd.onprem> | SSO via Keycloak or admin/secrets.tfvars: argocd_admin |
| Vault UI | <https://vault.onprem> | SSO via Keycloak (OIDC) or root token below |
| Keycloak | <https://keycloak.onprem> | secrets.tfvars: keycloak_admin |

**Vault root token:**

```bash
kubectl -n vault get secret vault-root-token -o jsonpath="{.data.token}" | base64 -d
```

**ArgoCD admin password:**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Disabled Components

The following components are disabled to fit within 16GB RAM. Code is preserved with comments — see each file for re-enable instructions.

| Component | File | How to Re-enable |
|-----------|------|------------------|
| Kafka UI | `helm/argo/cd/values.yaml` | `applications.kafkaUi.enabled: true` |
| Juice Shop | `helm/argo/cd/values.yaml` | `applications.juiceShop.enabled: true` |
| Loki chunks cache | `helm/observability/monitoring/values-loki.yaml` | `chunksCache.enabled: true` + uncomment resources |
| Loki results cache | `helm/observability/monitoring/values-loki.yaml` | `resultsCache.enabled: true` + uncomment resources |

## Cleanup

Destroy the cluster stack while preserving AWS resources, transit Vault, and the registry cache:

```bash
terragrunt run --all destroy --non-interactive \
  --filter "!path:aws/iam" \
  --filter "!path:vault/transit" \
  --filter "!path:registry/cache"
```

### Shell Aliases

Add to `~/.bash_aliases` for convenience:

```bash
tg-apply()  { terragrunt run --all apply --non-interactive --working-dir terraform/live; }
tg-destroy() { terragrunt run --all destroy --non-interactive --working-dir terraform/live --queue-exclude-dir "aws/*" --queue-exclude-dir "vault/transit" --queue-exclude-dir "registry/*"; }
```
