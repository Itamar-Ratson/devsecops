# terraform/modules/hcp-workspace/variables.tf
variable "execution_mode" {
  description = "Workspace execution mode: 'local' for dev (accesses local Docker/KinD), 'remote' for future prod"
  type        = string
  default     = "local"

  validation {
    condition     = contains(["local", "remote", "agent"], var.execution_mode)
    error_message = "execution_mode must be one of: local, remote, agent."
  }
}

variable "organization" {
  description = "HCP Terraform organization name"
  type        = string
}

variable "workspace_name" {
  description = "Full HCP Terraform workspace name (e.g. devsecops-vault-transit)"
  type        = string
}
