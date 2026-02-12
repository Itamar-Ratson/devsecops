output "workspace_ids" {
  description = "Map of workspace name suffix to workspace ID"
  value       = { for k, v in tfe_workspace.this : k => v.id }
}
