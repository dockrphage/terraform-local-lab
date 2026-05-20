# outputs.tf

output "deployed_services" {
  description = "List of deployed service names and their IPs"
  value = {
    for key, container in docker_container.multi_service : key => container.network_data[0].ip_address
  }
}

output "container_names" {
  description = "Full names of all containers"
  value       = [for c in docker_container.multi_service : c.name]
}