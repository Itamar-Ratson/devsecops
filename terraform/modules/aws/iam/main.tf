# ============================================================================
# Data sources
# ============================================================================
data "aws_caller_identity" "current" {}

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_kms_key" "ssm" {
  key_id = "alias/aws/ssm"
}

# ============================================================================
# GitHub Actions OIDC provider
# ============================================================================
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

# ============================================================================
# GitHub Actions IAM role
# ============================================================================
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# ============================================================================
# SSM read policy (shared by CI role and team group)
# ============================================================================
data "aws_iam_policy_document" "ssm_read" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParameters", "ssm:DescribeParameters"]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.ssm.arn]
  }
}

resource "aws_iam_policy" "ssm_read" {
  name   = "${var.project_name}-ssm-read"
  policy = data.aws_iam_policy_document.ssm_read.json
}

resource "aws_iam_role_policy_attachment" "github_actions_ssm" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

# ============================================================================
# Team member IAM group + users
# ============================================================================
resource "aws_iam_group" "team" {
  name = "${var.project_name}-team"
}

resource "aws_iam_group_policy_attachment" "team_ssm" {
  group      = aws_iam_group.team.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

resource "aws_iam_user" "member" {
  for_each = var.team_members
  name     = each.key
}

resource "aws_iam_access_key" "member" {
  for_each = var.team_members
  user     = aws_iam_user.member[each.key].name
}

resource "aws_iam_user_group_membership" "member" {
  for_each = var.team_members
  user     = aws_iam_user.member[each.key].name
  groups   = [aws_iam_group.team.name]
}
