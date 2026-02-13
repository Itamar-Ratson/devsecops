output "container_name" {
  description = "Zot registry cache container name"
  value       = docker_container.zot.name
}

output "container_id" {
  description = "Zot registry cache container ID"
  value       = docker_container.zot.id
}
