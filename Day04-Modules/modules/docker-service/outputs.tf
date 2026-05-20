# modules/docker-service/outputs.tf

output "container_id" {
  value = docker_container.service.id
}

output "container_ip" {
  value = docker_container.service.network_data[0].ip_address
}

output "container_name" {
  value = docker_container.service.name
}