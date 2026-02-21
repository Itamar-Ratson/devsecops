# SSM Admin Guide

This runbook covers all admin operations for the AWS SSM secrets distribution system.

## First-Time Setup (once per shared cluster)

```bash
# 1. Configure AWS CLI with admin credentials
aws configure
# AWS Access Key ID:     <admin access key>
# AWS Secret Access Key: <admin secret key>
# Default region name:   us-east-1
# Default output format: json

# 2. Create IAM infrastructure
cd terraform/live/aws/iam
cp team-members.csv.example team-members.csv
# Edit team-members.csv: add a username per line for each team member
terragrunt apply --non-interactive

# 3. Retrieve access keys for each team member
terraform output -json iam_access_keys | jq 'to_entries[] | {user: .key, key_id: .value.access_key_id}'
# IMPORTANT: deliver secret keys via a secure channel (not Slack/email plaintext)

# 4. Seed SSM parameters
cd ../ssm
cp ../../secrets.tfvars.example ../../secrets.tfvars
# Fill in ALL values in secrets.tfvars (see README.md for generation commands)
terragrunt apply --non-interactive

# 5. Apply the full stack
cd ../../
terragrunt run --all apply --non-interactive

# 6. Revoke the Vault root token (after vault/transit applies successfully)
vault login <root_token>
vault token revoke -self
# Optionally delete secrets.tfvars -- it is no longer needed for day-to-day runs.
# Keep it safe if you may need to re-seed SSM (e.g. disaster recovery).
```

## Adding a Team Member

```bash
# 1. Add username to team-members.csv
echo "carol" >> terraform/live/aws/iam/team-members.csv

# 2. Apply IAM
cd terraform/live/aws/iam
terragrunt apply --non-interactive

# 3. Retrieve Carol's access key
terraform output -json iam_access_keys | jq '.carol'

# 4. Deliver access key ID + secret to Carol via secure channel
```

## Removing a Team Member

```bash
# 1. Remove the username from team-members.csv
# 2. Apply IAM -- the IAM user and access key are destroyed immediately
cd terraform/live/aws/iam
terragrunt apply --non-interactive
```

## Rotating a Secret

```bash
# Option A: via AWS CLI (immediate, no Terraform state change)
aws ssm put-parameter \
  --name "/devsecops/<param-name>" \
  --value "<new-value>" \
  --type SecureString \
  --overwrite

# Then re-apply the consuming module:
cd terraform/live/vault/config && terragrunt apply --non-interactive
# or
cd terraform/live/k8s/bootstrap/argocd && terragrunt apply --non-interactive

# Option B: via Terraform (updates state too)
# Edit secrets.tfvars, then:
cd terraform/live/aws/ssm && terragrunt apply --non-interactive
# Then re-apply consuming modules as above.
```

## SSM Parameter Reference

| SSM Path | Consumer |
|----------|----------|
| `/devsecops/github-token` | argocd (run_cmd in terragrunt.hcl) |
| `/devsecops/oidc-argocd` | argocd (run_cmd) + vault/config (data source) |
| `/devsecops/oidc-grafana` | vault/config |
| `/devsecops/oidc-vault` | vault/config |
| `/devsecops/oidc-headlamp` | vault/config |
| `/devsecops/keycloak-admin-username` | vault/config |
| `/devsecops/keycloak-admin-password` | vault/config |
| `/devsecops/grafana-admin-username` | vault/config |
| `/devsecops/grafana-admin-password` | vault/config |
| `/devsecops/argocd-admin-password-hash` | vault/config |
| `/devsecops/argocd-server-secret-key` | vault/config |
| `/devsecops/alertmanager-pagerduty-routing-key` | vault/config (DISABLED = disabled) |
| `/devsecops/alertmanager-slack-critical-webhook` | vault/config (DISABLED = disabled) |
| `/devsecops/alertmanager-slack-warning-webhook` | vault/config (DISABLED = disabled) |

## GitHub Actions Repository Variables

Set in repository Settings > Secrets and Variables > Variables (not Secrets):

| Variable | Value |
|----------|-------|
| `AWS_ACCOUNT_ID` | Your AWS account ID (12-digit number) |
| `AWS_REGION` | AWS region (e.g., `us-east-1`) |
