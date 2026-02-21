output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role (use in workflow: role-to-assume)"
  value       = aws_iam_role.github_actions.arn
}

output "iam_access_keys" {
  description = "Access key ID and secret for each team member (deliver via secure channel)"
  sensitive   = true
  value = {
    for username in keys(var.team_members) : username => {
      access_key_id     = aws_iam_access_key.member[username].id
      secret_access_key = aws_iam_access_key.member[username].secret
    }
  }
}
