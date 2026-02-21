variable "aws_region" {
  description = "AWS region (used in SSM ARN policy)"
  type        = string
}

variable "github_org" {
  description = "GitHub organisation or user that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix)"
  type        = string
}

variable "project_name" {
  description = "Project name used as SSM path prefix and in resource names"
  type        = string
  default     = "devsecops"
}

variable "team_members" {
  description = "Map of team member usernames to empty objects (keys = IAM usernames)"
  type        = map(object({}))
  default     = {}
}
