# SSM Secrets Distribution Design

> **For Claude:** REQUIRED SUB-SKILL: Use `superpowers:writing-plans` to create the implementation plan for this design.

**Goal:** Replace the gitignored `secrets.tfvars` file with AWS SSM Parameter Store so team members can onboard and run `terragrunt apply` without receiving secrets out-of-band.

**Architecture:** Two-layer secrets model. AWS SSM holds Terraform bootstrap secrets (what currently lives in `secrets.tfvars`). The existing Transit Vault + VSO pipeline for runtime Kubernetes secrets is unchanged. An admin seeds SSM once from a local `secrets.tfvars`; all subsequent applies read from SSM.

**Tech stack:** AWS SSM Parameter Store (Standard tier, free), AWS IAM, Terraform `aws` provider, Terragrunt, GitHub Actions OIDC, `csvdecode()` built-in.

---

## 1. Two-Layer Secrets Model

```
LAYER 1 — Terraform bootstrap (new)
  Admin machine:
    secrets.tfvars      →  terragrunt apply aws/ssm  →  AWS SSM Parameter Store
    team-members.csv    →  terragrunt apply aws/iam  →  AWS IAM users + roles

  Team member machine:
    aws configure (one-time)  →  terragrunt run --all apply  →  reads SSM automatically

  GitHub Actions:
    GitHub OIDC token  →  AssumeRole (IAM)  →  reads SSM  →  terragrunt apply

LAYER 2 — Runtime K8s secrets (unchanged)
  AWS SSM  →  vault-config module  →  Transit Vault  →  VSO  →  K8s Secrets  →  Pods
```

Transit Vault + VSO pipeline is completely unchanged. SSM replaces only the Terraform input mechanism.

---

## 2. New Terraform Structure

```
terraform/
  live/
    aws/                          ← new top-level grouping
      iam/
        terragrunt.hcl            ← admin-only: IAM OIDC provider, GitHub Actions role,
                                     team member users; reads team-members.csv
      ssm/
        terragrunt.hcl            ← admin-only: seeds SSM params from secrets.tfvars
  modules/
    aws/
      iam/
        main.tf                   ← OIDC provider, CI/CD role, team users, policies
        variables.tf
        outputs.tf
      ssm/
        main.tf                   ← aws_ssm_parameter resources
        variables.tf              ← same secret structure as secrets.tfvars (minus vault_root_token)
        outputs.tf                ← sensitive outputs for downstream dependency blocks
```

### Admin-only input files (both gitignored)

| File | Used by | Format |
|------|---------|--------|
| `terraform/live/secrets.tfvars` | `aws/ssm` (seed), `vault/transit` (root token only) | HCL |
| `terraform/live/aws/iam/team-members.csv` | `aws/iam` | CSV |

Both follow the same pattern as today's `secrets.tfvars`: local to admin machine, never committed.
Committed example files document the expected format.

---

## 3. SSM Parameter Map

All parameters are `SecureString` type encrypted with the default `aws/ssm` AWS-managed key (free).
Path prefix: `/devsecops/`.

| SSM Path | Secret | Module that reads it |
|----------|--------|----------------------|
| `/devsecops/github-token` | GitHub deploy token | `k8s/bootstrap/argocd` |
| `/devsecops/git-repo-url` | Git repository URL | `k8s/bootstrap/argocd` |
| `/devsecops/argocd-oidc-client-secret` | ArgoCD OIDC client secret | `k8s/bootstrap/argocd` |
| `/devsecops/oidc-argocd` | ArgoCD OIDC secret (Vault copy) | `vault/config` |
| `/devsecops/oidc-grafana` | Grafana OIDC secret | `vault/config` |
| `/devsecops/oidc-vault` | Vault OIDC secret | `vault/config` |
| `/devsecops/oidc-headlamp` | Headlamp OIDC secret | `vault/config` |
| `/devsecops/keycloak-admin-username` | Keycloak admin username | `vault/config` |
| `/devsecops/keycloak-admin-password` | Keycloak admin password | `vault/config` |
| `/devsecops/grafana-admin-username` | Grafana admin username | `vault/config` |
| `/devsecops/grafana-admin-password` | Grafana admin password | `vault/config` |
| `/devsecops/argocd-admin-password-hash` | ArgoCD admin bcrypt hash | `vault/config` |
| `/devsecops/argocd-server-secret-key` | ArgoCD server secret key | `vault/config` |
| `/devsecops/alertmanager-pagerduty-routing-key` | PagerDuty routing key | `vault/config` |
| `/devsecops/alertmanager-slack-critical-webhook` | Slack critical webhook URL | `vault/config` |
| `/devsecops/alertmanager-slack-warning-webhook` | Slack warning webhook URL | `vault/config` |

**`vault_root_token` is NOT in SSM.** It stays in `secrets.tfvars` on the admin machine, used only by `vault/transit` to initialise Transit Vault. It must be revoked after the first successful apply of `vault/transit`.

**Optional parameters** (alertmanager webhooks): seeded with the sentinel value `"DISABLED"` when not configured. Consuming modules treat this value as "feature disabled" rather than leaving the parameter absent (absent parameters cause `data.aws_ssm_parameter` to fail).

---

## 4. Changes to Existing Modules

Existing module Terraform code (`main.tf`, `variables.tf`) is **unchanged** — they continue to accept variables. Only the three `terragrunt.hcl` wiring files change.

### `vault/transit/terragrunt.hcl`
- `vault_root_token` still comes from `secrets.tfvars` via `optional_var_files` (unchanged — root token is admin-only, one-time)
- No SSM dependency needed here

### `vault/config/terragrunt.hcl`
- Remove `extra_arguments "secrets"` / `optional_var_files` block
- Add `dependencies { paths = ["../../aws/ssm"] }` (ordering-only — `vault/config` is filtered in CI, so cannot use output-fetching `dependency`)
- Add `aws_ssm_parameter` data sources inside the module to read its secrets directly (avoids passing secrets through Terragrunt outputs into HCP state of this module)

### `k8s/bootstrap/argocd/terragrunt.hcl`
- Remove `extra_arguments "secrets"` / `optional_var_files` block
- Add `dependency "aws_ssm"` (output-fetching — this module is not filtered in CI)
- Pass `git_repo_url`, `github_token`, `argocd_oidc_client_secret` via `inputs` from SSM outputs

---

## 5. IAM Resources (all via Terraform)

### `aws/iam` module

```hcl
# GitHub Actions OIDC
aws_iam_openid_connect_provider  "github"
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [current thumbprint]

aws_iam_role  "github_actions"
  trust policy condition:
    StringLike "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:*"
    # Covers both push and pull_request events

aws_iam_policy  "ssm_read"
  ssm:GetParameter, ssm:GetParameters on arn:...:parameter/devsecops/*
  kms:Decrypt on the aws/ssm managed key ARN

aws_iam_role_policy_attachment  (github_actions + ssm_read)

# Team members
aws_iam_group              "devsecops_team"
aws_iam_group_policy_attachment  (devsecops_team + ssm_read)

# Per member (from team-members.csv via csvdecode):
aws_iam_user               "member[username]"
aws_iam_access_key         "member[username]"   ← secret key in HCP state (see trade-offs)
aws_iam_user_group_membership  "member[username]"
```

### Team members CSV

```csv
# terraform/live/aws/iam/team-members.csv  (gitignored)
username
alice
bob
```

Read in Terraform locals:
```hcl
locals {
  team_members = {
    for row in csvdecode(file("${path.module}/team-members.csv")) :
    row.username => {}
  }
}
```

Adding a member: edit CSV → `terragrunt apply aws/iam` → IAM user + access key created.
Removing a member: remove from CSV → `terragrunt apply aws/iam` → IAM user + key destroyed (access invalidated immediately).

---

## 6. GitHub Actions CI/CD Changes

### Workflow permission block (add `id-token: write`)
```yaml
permissions:
  id-token: write      # ← required for OIDC token minting
  contents: read
  packages: write
  security-events: write
  pull-requests: write
```

### AWS credentials step (add before terragrunt apply)
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/devsecops-github-actions
    aws-region: ${{ vars.AWS_REGION }}
```

`AWS_ACCOUNT_ID` and `AWS_REGION` are GitHub Actions variables (not secrets — not sensitive).

### CI secrets step
The existing "Create CI secrets" step that writes `secrets.tfvars` is removed for all secrets now in SSM. `secrets.tfvars` is no longer present in CI. The `aws/ssm` module is excluded from CI runs (it is admin-only).

---

## 7. Deploy Order

```
BOOTSTRAP (admin, one-time — not part of run --all):
  aws/iam    ← IAM infrastructure: OIDC provider, CI role, team users
  aws/ssm    ← seed SSM parameters from secrets.tfvars

REGULAR (run --all apply/destroy — aws/iam and aws/ssm excluded via --filter):
  hcp-workspaces
    └─► vault/transit    (still reads vault_root_token from secrets.tfvars)
          └─► k8s/kind
                └─► k8s/bootstrap/cluster
                      ├─► vault/config          (reads from SSM data sources)
                      └─► k8s/bootstrap/argocd  (reads from aws/ssm dependency outputs)
```

`aws/iam` and `aws/ssm` are excluded from all `run --all` invocations (both apply and destroy) by adding them to the filter list. They are never part of CI. They are only ever applied manually by the admin.

`hcp-workspaces` must be updated to register `devsecops-aws-iam` and `devsecops-aws-ssm` workspaces.

---

## 8. Terrascan Update

The existing terrascan before-hook in `root.hcl` currently scans only `k8s` and `docker` policy types. Add `aws`:

```hcl
--policy-type k8s --policy-type docker --policy-type aws
```

---

## 9. Admin Guide

_Full runbook: `docs/runbooks/ssm-admin-guide.md`_

### First-time setup (once per shared cluster)

```bash
# 1. Configure AWS CLI with admin credentials
aws configure

# 2. Create IAM infrastructure
cd terraform/live/aws/iam
cp team-members.csv.example team-members.csv
# Edit team-members.csv: add initial team member usernames
terragrunt apply --non-interactive

# 3. Retrieve access keys for each team member
#    (from HCP Terraform outputs or: terraform output -json)
#    Deliver to each member via a secure channel (not Slack/email plaintext)

# 4. Seed SSM parameters
cd ../ssm
# Ensure secrets.tfvars exists and is fully populated
terragrunt apply --non-interactive

# 5. Apply the full stack
cd ../../
terragrunt run --all apply --non-interactive \
  --filter '!aws/iam' \
  --filter '!aws/ssm' \
  --filter '!hcp-workspaces'

# 6. Revoke the Vault root token (after vault/transit has applied successfully)
#    Retrieve the token, log in, revoke:
vault login <root_token>
vault token revoke -self
#    Delete secrets.tfvars from your machine — it is no longer needed
rm terraform/live/secrets.tfvars
```

### Adding a team member

```bash
# 1. Add username to team-members.csv
echo "carol" >> terraform/live/aws/iam/team-members.csv

# 2. Apply IAM
cd terraform/live/aws/iam
terragrunt apply --non-interactive

# 3. Retrieve Carol's access key from outputs
terraform output -json iam_access_keys | jq '.carol'

# 4. Deliver access key ID + secret to Carol via secure channel
```

### Removing a team member

```bash
# 1. Remove username from team-members.csv
# 2. Apply IAM — IAM user and access key are destroyed (key invalidated immediately)
cd terraform/live/aws/iam
terragrunt apply --non-interactive
```

### Rotating a secret

```bash
# 1. Update the value in AWS SSM (console or CLI):
aws ssm put-parameter \
  --name "/devsecops/<param-name>" \
  --value "<new-value>" \
  --type SecureString \
  --overwrite

# 2. Re-apply the modules that consume it:
cd terraform/live/vault/config && terragrunt apply --non-interactive
# or
cd terraform/live/k8s/bootstrap/argocd && terragrunt apply --non-interactive
```

---

## 10. Team Member Guide

_Full runbook: `docs/runbooks/ssm-member-guide.md`_

### First-time onboarding

```bash
# 1. Install AWS CLI
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

# 2. Configure with the access key your admin provided
aws configure
# AWS Access Key ID:     <from admin>
# AWS Secret Access Key: <from admin>
# Default region name:   us-east-1   (or as instructed)
# Default output format: json

# 3. Clone the repo and apply
git clone <repo-url>
cd devsecops/terraform/live
terragrunt run --all apply --non-interactive
```

That's it. No secrets files, no passwords to manage.

### Day-to-day

```bash
# Apply changes
cd terraform/live
terragrunt run --all apply --non-interactive

# Destroy cluster (preserves registry)
terragrunt run --all destroy --non-interactive \
  --filter '!registry/cache'
```

---

## 11. Known Trade-offs

| Trade-off | Decision | Mitigation |
|-----------|----------|------------|
| IAM access key secret stored in HCP Terraform state (encrypted) | Accepted | Tightly control HCP org membership; future: migrate to AWS IAM Identity Center |
| `vault_root_token` still in `secrets.tfvars` on admin machine | Accepted | Admin-only, used once, revoked after first apply |
| SSM outage blocks all `terragrunt apply` runs | Accepted | Dev cluster — acceptable downtime; break-glass: restore `secrets.tfvars` temporarily |
| Secrets flow through HCP state in `k8s/bootstrap/argocd` (via dependency outputs) | Accepted | HCP Terraform encrypts state; `vault/config` avoids this via data sources |

---

## 12. Future Work

- Migrate team member auth from IAM access keys to **AWS IAM Identity Center** (no long-lived keys, no state exposure)
- Host `team-members.csv` in **S3** — replace `file()` with `aws_s3_object` data source, no other changes needed
- Add **email field** to CSV when needed for notifications
- Deepen **SSM path structure** (`/devsecops/<env>/<component>/`) when multiple environments are introduced
- Add **Keycloak → AWS federation** so team members authenticate to AWS via their Keycloak SSO identity
- Add **CloudWatch alerting** on SSM GetParameter calls for high-sensitivity paths
- Add **IAM permission boundaries** on team member users
