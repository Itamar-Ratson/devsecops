# Secrets and Credentials Inventory

Complete inventory of all secrets, keys, tokens, and credentials used in the DevSecOps project, with recreation instructions.

## Secret Flow Overview

```
secrets.tfvars (admin, one-time)
        |
        v
  aws/ssm module ──> AWS SSM Parameter Store (SecureString)
                              |
                              v
                      vault/config module ──> Vault KV v2 (secret/)
                                                    |
                                                    v
                                              VSO (VaultStaticSecret)
                                                    |
                                                    v
                                              Kubernetes Secrets ──> Application Pods
```

**One-time bootstrap**: Admin populates `secrets.tfvars`, applies `aws/ssm` to seed SSM. After that, team members only need AWS credentials — the rest is automated.

**Runtime flow**: Terraform `vault/config` reads SSM and writes to Vault KV v2. VSO watches VaultStaticSecret CRDs and syncs Vault secrets into Kubernetes Secrets. Apps read K8s Secrets.

## Prerequisites

- AWS CLI configured with credentials (`aws sts get-caller-identity` succeeds)
- `openssl` (generating random secrets)
- `htpasswd` from `apache2-utils` (ArgoCD password hash)
- Access to: [Cloudflare dashboard](https://dash.cloudflare.com), [Tailscale admin](https://login.tailscale.com/admin), [GitHub settings](https://github.com/settings/tokens)

## 1. Bootstrap Secrets (`secrets.tfvars`)

The template is at `terraform/live/secrets.tfvars.example`. Copy to `terraform/live/secrets.tfvars` and fill in values. **Never commit `secrets.tfvars` to git.**

Apply once:

```bash
cd terraform/live/aws/ssm && terragrunt apply --non-interactive
```

### `vault_root_token`

| Field | Value |
|-------|-------|
| Purpose | Transit Vault dev-mode root token (`VAULT_DEV_ROOT_TOKEN_ID`) |
| Used by | `terraform/live/vault/transit` |
| Generate | `openssl rand -base64 32` |
| Lifecycle | One-time. Revoke after first successful `vault/transit` apply. |
| CI override | Set to `ci-test-token` (dummy) in workflow |

## 2. GitHub Actions

### Repository Secrets

Set via: **Repo > Settings > Secrets and variables > Actions > New repository secret**, or:

```bash
gh secret set <NAME>
```

| Secret | Purpose | How to create | Used in |
|--------|---------|---------------|---------|
| `PACKAGES_PAT` | GitHub PAT with `read:packages` scope for pulling GHCR images | [GitHub > Settings > Developer settings > Personal access tokens > Fine-grained tokens](https://github.com/settings/tokens?type=beta) — scope: `read:packages` | `deployment-and-dast.yaml` (Zot cache warming, image saving) |
| `ARGOCD_GITHUB_TOKEN` | **Likely stale.** Not referenced in any workflow or code. The GitHub token for ArgoCD deploy keys is now sourced from AWS SSM (`/devsecops/github-token`) via `run_cmd` in terragrunt. Verify and remove if unused. | N/A | Not referenced |

> **Note**: `GITHUB_TOKEN` is auto-provided by GitHub Actions — no manual setup needed.

### Repository Variables

Set via: **Repo > Settings > Secrets and variables > Actions > Variables**, or:

```bash
gh variable set <NAME> --body "<VALUE>"
```

| Variable | Purpose | Value |
|----------|---------|-------|
| `AWS_ACCOUNT_ID` | AWS account for GitHub OIDC `AssumeRole` | Your AWS account ID |
| `AWS_REGION` | AWS region for infrastructure | e.g., `eu-north-1` |

### GitHub OIDC > AWS

The CI workflows authenticate to AWS using GitHub OIDC (not static keys). This requires an IAM role `devsecops-github-actions` with a trust policy allowing the repo's OIDC tokens. The role ARN is:

```
arn:aws:iam::<AWS_ACCOUNT_ID>:role/devsecops-github-actions
```

This role needs permissions to read SSM parameters, manage KinD infrastructure, and interact with GHCR.

## 3. AWS SSM Parameters

All stored under the `/devsecops/` prefix as `SecureString` (KMS-encrypted) unless noted. Seeded by the `aws/ssm` Terraform module from `secrets.tfvars`.

After initial seeding, individual parameters can be updated directly:

```bash
aws ssm put-parameter \
  --name "/devsecops/<param-name>" \
  --value "<value>" \
  --type SecureString \
  --overwrite
```

### OIDC Client Secrets (Keycloak)

One secret per OIDC-integrated service. These must match the client secrets configured in Keycloak realm clients.

| SSM Path | Service | Generate | `secrets.tfvars` key |
|----------|---------|----------|---------------------|
| `/devsecops/oidc-argocd` | ArgoCD SSO | `openssl rand -hex 32` | `oidc_client_secrets.argocd` |
| `/devsecops/oidc-grafana` | Grafana SSO | `openssl rand -hex 32` | `oidc_client_secrets.grafana` |
| `/devsecops/oidc-vault` | Vault UI SSO | `openssl rand -hex 32` | `oidc_client_secrets.vault` |
| `/devsecops/oidc-headlamp` | Headlamp + kube-oidc-proxy | `openssl rand -hex 32` | `oidc_client_secrets.headlamp` |
| `/devsecops/oidc-cloudflare-access` | Cloudflare Access | `openssl rand -hex 32` | `oidc_client_secrets.cloudflare-access` |

> **Important**: After generating new OIDC secrets, you must also update the corresponding Keycloak realm client credentials to match. The Keycloak realm is configured via `helm/identity/keycloak/` — update the client secret in the realm JSON or via the Keycloak admin console.

### Admin Credentials

| SSM Path | Purpose | Generate | `secrets.tfvars` key |
|----------|---------|----------|---------------------|
| `/devsecops/keycloak-admin-username` | Keycloak admin login | Choose a username (default: `admin`) | `keycloak_admin.username` |
| `/devsecops/keycloak-admin-password` | Keycloak admin password | Choose a strong password | `keycloak_admin.password` |
| `/devsecops/grafana-admin-username` | Grafana admin login | Choose a username (default: `admin`) | `grafana_admin.username` |
| `/devsecops/grafana-admin-password` | Grafana admin password | Choose a strong password | `grafana_admin.password` |
| `/devsecops/argocd-admin-password-hash` | ArgoCD admin (bcrypt hash) | `htpasswd -nbBC 10 "" 'your-password' \| tr -d ':\n'` | `argocd_admin.password_hash` |
| `/devsecops/argocd-server-secret-key` | ArgoCD session encryption key | `openssl rand -base64 32` | `argocd_admin.server_secret_key` |

### GitHub Token

| SSM Path | Purpose | Generate | `secrets.tfvars` key |
|----------|---------|----------|---------------------|
| `/devsecops/github-token` | Manage ArgoCD deploy keys on GitHub | [GitHub PAT](https://github.com/settings/tokens) with `admin:repo_key` or `repo` scope | `github_token` |

> Used by `terraform/live/k8s/bootstrap/argocd/terragrunt.hcl` via `run_cmd` at plan/apply time. Only needed for local deploys with SSH deploy keys (`create_deploy_key = true`). CI uses HTTPS (public repo).

### Cloudflare

| SSM Path | Type | Purpose | Generate | `secrets.tfvars` key |
|----------|------|---------|----------|---------------------|
| `/devsecops/cloudflare-api-token` | SecureString | API token for DNS-01 ACME, Tunnel, Access | [Cloudflare dashboard > My Profile > API Tokens](https://dash.cloudflare.com/profile/api-tokens) — permissions: `Tunnel:Edit`, `Zone:Edit`, `DNS:Edit`, `Account:Read` | `cloudflare_api_token` |
| `/devsecops/cloudflare-account-id` | String | Cloudflare account identifier | Cloudflare dashboard > account overview (top-right) | `cloudflare_account_id` |
| `/devsecops/cloudflare-zone-id` | String | Zone ID for your domain | Cloudflare dashboard > domain overview (right sidebar) | `cloudflare_zone_id` |

### Tailscale OAuth

| SSM Path | Purpose | Generate | `secrets.tfvars` key |
|----------|---------|----------|---------------------|
| `/devsecops/tailscale-oauth-client-id` | Tailscale K8s operator OAuth client ID | [Tailscale admin > Settings > OAuth clients](https://login.tailscale.com/admin/settings/oauth) — create client with `Devices: Write` scope, tag: `tag:k8s-operator` | `tailscale_oauth_client_id` |
| `/devsecops/tailscale-oauth-client-secret` | Tailscale K8s operator OAuth client secret | Generated alongside client ID above | `tailscale_oauth_client_secret` |

> **Rotation**: Tailscale OAuth clients don't expire, but auth keys do (90 days). A GitHub Actions workflow (`tailscale-key-rotation.yaml`) sends Slack reminders every 60 days.

### Alertmanager Webhooks (Optional)

Use `DISABLED` sentinel value to disable a channel. The `vault/config` module converts `DISABLED` to an empty string.

| SSM Path | Purpose | Generate | `secrets.tfvars` key |
|----------|---------|----------|---------------------|
| `/devsecops/alertmanager-pagerduty-routing-key` | PagerDuty integration | [PagerDuty > Services > Integrations > Events API v2](https://support.pagerduty.com/docs/services-and-integrations) — copy routing key | `alertmanager_webhooks.pagerduty_routing_key` |
| `/devsecops/alertmanager-slack-critical-webhook` | Slack channel for critical alerts | [Slack > Apps > Incoming Webhooks](https://api.slack.com/messaging/webhooks) — create webhook for `#alerts-critical` | `alertmanager_webhooks.slack_critical_webhook` |
| `/devsecops/alertmanager-slack-warning-webhook` | Slack channel for warning alerts | Same as above for `#alerts-warning` | `alertmanager_webhooks.slack_warning_webhook` |

### Other

| SSM Path | Type | Purpose | Generate | `secrets.tfvars` key |
|----------|------|---------|----------|---------------------|
| `/devsecops/letsencrypt-email` | String | Let's Encrypt certificate expiry notifications | Your email address | `letsencrypt_email` |
| `/devsecops/slack-devops-webhook` | SecureString | Slack webhook for Tailscale key rotation reminders | [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks) for your DevOps channel | `slack_devops_webhook` |

## 4. Vault KV v2 Secrets

**No manual action needed.** These are auto-populated by the `terraform/modules/vault/config/` module, which reads from AWS SSM and writes to Vault.

Listed here for debugging and reference. All paths are under the `secret/` KV v2 mount.

| Vault Path | Keys | Source SSM Parameters |
|------------|------|----------------------|
| `secret/keycloak/oidc-clients` | `argocd-client-secret`, `grafana-client-secret`, `vault-client-secret`, `headlamp-client-secret`, `cloudflare-access-client-secret` | `/devsecops/oidc-*` |
| `secret/keycloak/admin` | `admin-user`, `admin-password` | `/devsecops/keycloak-admin-{username,password}` |
| `secret/monitoring/grafana` | `admin-user`, `admin-password` | `/devsecops/grafana-admin-{username,password}` |
| `secret/monitoring/alertmanager` | `pagerduty-routing-key`, `slack-critical-webhook`, `slack-warning-webhook` | `/devsecops/alertmanager-*` |
| `secret/cloudflare/api-token` | `api-token` | `/devsecops/cloudflare-api-token` |
| `secret/argocd/admin` | `admin.password`, `server.secretkey` | `/devsecops/argocd-admin-*`, `/devsecops/argocd-server-secret-key` |
| `secret/tailscale/operator` | `client_id`, `client_secret` | `/devsecops/tailscale-oauth-client-{id,secret}` |

## 5. Kubernetes Secrets

### Pre-created by Terraform

These are created by `terraform/modules/k8s/bootstrap/argocd/secrets.tf` before ArgoCD or VSO exist.

| Secret Name | Namespace | Purpose | How it's created |
|-------------|-----------|---------|-----------------|
| `argocd-redis` | `argocd` | Redis auth for ArgoCD session store | `random_password` (32 chars, no special) — auto-generated by Terraform, no manual input |
| `vault-transit-token` | `secrets` | Transit Vault token for Vault pod bootstrap | `var.vault_root_token` passed from `vault/transit` dependency |
| `argocd-repo-creds` | `argocd` | SSH deploy key for ArgoCD Git access | Auto-generated ED25519 key pair (`tls_private_key`). Only created when `create_deploy_key = true` (local only, skipped in CI) |
| `argocd-oidc-secret` | `argocd` | ArgoCD OIDC client secret (pre-seed before VSO) | From SSM `/devsecops/oidc-argocd` via terragrunt `run_cmd`. Later overwritten by VSO. |

### VaultStaticSecrets (VSO-managed)

These are created by VaultStaticSecret CRDs in Helm chart templates. VSO watches them and syncs Vault secrets into K8s Secrets automatically. **No manual action needed** — they are recreated on every deploy.

| K8s Secret | Namespace | Vault Source | Helm Chart |
|------------|-----------|-------------|------------|
| `keycloak-admin-credentials` | `identity` | `secret/keycloak/admin` | `helm/identity/keycloak/` |
| `keycloak-oidc-clients` | `identity` | `secret/keycloak/oidc-clients` | `helm/identity/keycloak/` |
| `argocd-admin-secret` | `argocd` | `secret/argocd/admin` | `helm/argo/cd/` |
| `argocd-oidc-secret` | `argocd` | `secret/keycloak/oidc-clients` | `helm/argo/cd/` |
| `grafana-admin-credentials` | `observability` | `secret/monitoring/grafana` | `helm/observability/monitoring/` |
| `grafana-oidc-secret` | `observability` | `secret/keycloak/oidc-clients` | `helm/observability/monitoring/` |
| `alertmanager-slack-webhooks` | `observability` | `secret/monitoring/alertmanager` | `helm/observability/monitoring/` |
| `cloudflare-api-token` | `cert-manager` | `secret/cloudflare/api-token` | `helm/networking/cert-manager/` |
| `headlamp-oidc-secret` | `observability` | `secret/keycloak/oidc-clients` | `helm/observability/headlamp/` |
| `kube-oidc-proxy-config` | `identity` | `secret/keycloak/oidc-clients` | `helm/identity/kube-oidc-proxy/` |
| `vault-oidc-secret` | `secrets` | `secret/keycloak/oidc-clients` | `helm/secrets/vault/server/` |
| `tailscale-operator-oauth` | `tailscale` | `secret/tailscale/operator` | `helm/networking/tailscale-operator/` |

## 6. TLS and Certificates

### ArgoCD Deploy Key (ED25519)

| Field | Value |
|-------|-------|
| Created by | `tls_private_key.argocd_deploy_key` in `terraform/modules/k8s/bootstrap/argocd/secrets.tf` |
| Condition | Only when `create_deploy_key = true` (local deploys only, CI uses HTTPS) |
| Public key | Auto-registered as GitHub repository deploy key (read-only) via `github_repository_deploy_key` resource |
| Private key | Stored in K8s secret `argocd-repo-creds` (argocd namespace) |
| Recreation | Automatic on `terragrunt apply` — Terraform generates a new key pair and registers it on GitHub |

### TLS Certificates (cert-manager)

All certificates are managed by cert-manager with Let's Encrypt ACME (DNS-01 challenge via Cloudflare). **No manual action needed** — certificates are auto-issued and auto-renewed.

Requirements:
- Cloudflare API token in Vault (from SSM `/devsecops/cloudflare-api-token`)
- Let's Encrypt email in SSM (`/devsecops/letsencrypt-email`)
- cert-manager ClusterIssuer configured in `helm/networking/cert-manager/`

## 7. Secret Rotation

### Rotating an SSM-sourced secret

1. Generate a new value (see the "Generate" column in section 3)
2. Update SSM:
   ```bash
   aws ssm put-parameter \
     --name "/devsecops/<param-name>" \
     --value "<new-value>" \
     --type SecureString \
     --overwrite
   ```
3. Re-apply `vault/config` to push the new value to Vault:
   ```bash
   cd terraform/live && terragrunt apply vault/config --non-interactive
   ```
4. VSO auto-refreshes K8s secrets (default: every 1 hour). To force immediate sync:
   ```bash
   kubectl annotate vaultstaticsecret <name> -n <namespace> \
     force-sync=$(date +%s) --overwrite
   ```
5. Restart affected pods if they don't watch for secret changes:
   ```bash
   kubectl rollout restart deployment/<name> -n <namespace>
   ```

### Rotating OIDC client secrets

Follow the SSM rotation steps above, **plus** update the Keycloak realm client to match the new secret (via admin console or realm JSON).

### Rotating the Tailscale OAuth client

1. Create a new OAuth client in [Tailscale admin](https://login.tailscale.com/admin/settings/oauth) with `Devices: Write` scope and `tag:k8s-operator`
2. Update both SSM parameters (`tailscale-oauth-client-id` and `tailscale-oauth-client-secret`)
3. Re-apply `vault/config` and restart the Tailscale operator pod

### Rotating the Cloudflare API token

1. Create a new token in [Cloudflare dashboard](https://dash.cloudflare.com/profile/api-tokens) with: `Tunnel:Edit`, `Zone:Edit`, `DNS:Edit`, `Account:Read`
2. Update SSM (`/devsecops/cloudflare-api-token`)
3. Re-apply `vault/config` and restart cert-manager + cloudflared pods
4. Revoke the old token in Cloudflare

## 8. Gitignored Files

| File | Contents | Why ignored |
|------|----------|-------------|
| `.env` | Development-only defaults for local testing | Contains plaintext secrets (admin passwords, OIDC secrets, Vault token) |
| `terraform/live/secrets.tfvars` | Full secret values for SSM seeding | Admin-only bootstrap file with all production secrets |
| `terraform/live/secrets.tfvars.example` | **Not ignored** — template with empty placeholders | Safe to commit, no secret values |

## 9. Full SSM Parameter Reference

Quick-reference list of all `/devsecops/*` SSM parameters:

```
/devsecops/github-token                        SecureString
/devsecops/oidc-argocd                         SecureString
/devsecops/oidc-grafana                        SecureString
/devsecops/oidc-vault                          SecureString
/devsecops/oidc-headlamp                       SecureString
/devsecops/oidc-cloudflare-access              SecureString
/devsecops/keycloak-admin-username             SecureString
/devsecops/keycloak-admin-password             SecureString
/devsecops/grafana-admin-username              SecureString
/devsecops/grafana-admin-password              SecureString
/devsecops/argocd-admin-password-hash          SecureString
/devsecops/argocd-server-secret-key            SecureString
/devsecops/cloudflare-api-token                SecureString
/devsecops/cloudflare-account-id               String
/devsecops/cloudflare-zone-id                  String
/devsecops/alertmanager-pagerduty-routing-key  SecureString
/devsecops/alertmanager-slack-critical-webhook SecureString
/devsecops/alertmanager-slack-warning-webhook  SecureString
/devsecops/letsencrypt-email                   String
/devsecops/slack-devops-webhook                SecureString
/devsecops/tailscale-oauth-client-id           SecureString
/devsecops/tailscale-oauth-client-secret       SecureString
```
