# outputs.tf

output "file_path" {
  description = "Path to the created local file"
  value       = local_file.greeting.filename
}

output "container_id" {
  description = "ID of the running Docker container"
  value       = docker_container.web_server.id
}

output "container_ip" {
  description = "IP address of the container"
  value       = docker_container.web_server.network_data[0].ip_address
}

output "access_url" {
  description = "URL to access the Nginx server"
  value       = "http://localhost:${var.container_port}"
}