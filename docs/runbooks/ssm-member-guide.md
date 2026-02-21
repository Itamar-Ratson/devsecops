# SSM Member Guide

How to onboard and work with the cluster as a team member.

## First-Time Onboarding

You need AWS credentials from your admin. They will send you:
- AWS Access Key ID
- AWS Secret Access Key

```bash
# 1. Install AWS CLI
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

# 2. Configure with the access key your admin provided
aws configure
# AWS Access Key ID:     <from admin>
# AWS Secret Access Key: <from admin>
# Default region name:   us-east-1  (or as instructed)
# Default output format: json

# 3. Clone the repo and apply
git clone git@github.com:itamar-ratson/devsecops.git  # or HTTPS if you prefer
cd devsecops/terraform/live
terragrunt run --all apply --non-interactive
```

That is it. No secrets files, no passwords to manage.

## Day-to-Day Operations

```bash
# Apply all changes
cd terraform/live
terragrunt run --all apply --non-interactive

# Destroy the cluster (keeps registry cache)
cd terraform/live
terragrunt run --all destroy --non-interactive \
  --filter '!registry/cache'
```

## Verify Your AWS Access

```bash
# Check AWS identity
aws sts get-caller-identity

# Test SSM access directly
aws ssm get-parameter \
  --name "/devsecops/oidc-grafana" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text
```

## Troubleshooting

**`run_cmd` fails with "Unable to locate credentials"**
> Run `aws configure` and verify your access key is set correctly.

**`run_cmd` fails with "AccessDeniedException"**
> Ask your admin to verify your IAM user is in the `devsecops-team` group.

**`data.aws_ssm_parameter` fails with "ParameterNotFound"**
> Ask your admin to seed SSM: `cd terraform/live/aws/ssm && terragrunt apply`.
