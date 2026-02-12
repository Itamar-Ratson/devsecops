variable "organization" {
  description = "HCP Terraform organization name"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for workspace naming"
  type        = string
}

variable "workspace_names" {
  description = "List of workspace suffixes (e.g. transit-vault, kind-cluster)"
  type        = list(string)
}
