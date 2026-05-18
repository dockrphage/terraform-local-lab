# outputs.tf

output "prometheus_url" {
  description = "URL to access Prometheus UI"
  value       = "http://localhost:30090"
}

output "grafana_url" {
  description = "URL to access Grafana UI"
  value       = "http://localhost:30300"
}

output "grafana_password" {
  description = "Admin password for Grafana"
  value       = "adminpassword"
  sensitive   = true # Hides it in the output log
}