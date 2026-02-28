# ============================================================================
# External Secrets Operator (ESO) — replaces VSO for EKS
# Uses IRSA for AWS authentication
# ============================================================================

locals {
  oidc_issuer = replace(var.cluster_oidc_issuer_url, "https://", "")
}

data "aws_caller_identity" "current" {}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

# IAM role for ESO (IRSA)
data "aws_iam_policy_document" "eso_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${var.cluster_name}-eso"
  assume_role_policy = data.aws_iam_policy_document.eso_trust.json

  tags = {
    Project   = "devsecops"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "eso_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/devsecops/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.target_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "eso" {
  name   = "eso-ssm-access"
  role   = aws_iam_role.eso.id
  policy = data.aws_iam_policy_document.eso_permissions.json
}

# ESO Helm release
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.14.3"
  wait             = true
  timeout          = 300

  set = [{
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.eso.arn
  }]

  # ArgoCD adopts this release after bootstrap and owns all day-2 changes.
  lifecycle {
    ignore_changes = all
  }
}

# ClusterSecretStore pointing to SSM ParameterStore
# Uses kubectl_manifest instead of kubernetes_manifest because the ESO CRDs
# don't exist at plan time on a clean apply.
resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-ssm"
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  })

  depends_on = [helm_release.external_secrets]
}
