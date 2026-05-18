# outputs.tf

output "web_ips" {
  description = "List of IP addresses for web servers"
  value       = docker_container.web_server[*].network_data[0].ip_address
}

output "web_count" {
  description = "Number of web servers running"
  value       = length(docker_container.web_server)
}

output "monitoring_active" {
  description = "Is monitoring running?"
  value       = var.enable_monitoring ? "Yes" : "No"
}

output "monitoring_ip" {
  description = "IP of the monitoring container (if active)"
  value = (
    var.enable_monitoring && length(docker_container.monitoring) > 0
    ? docker_container.monitoring[0].network_data[0].ip_address
    : null
  )
}
