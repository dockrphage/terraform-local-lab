# outputs.tf

output "app_url" {
  description = "URL to access the app"
  # value       = "http://localhost:${kubernetes_service.app.spec[0].port[0].node_port}"
  value       = "http://localhost:${kubernetes_service.app.spec[0].port[0].node_port}"
}

output "pod_name" {
  # value = kubernetes_deployment.app.status.replicas > 0 ? kubernetes_deployment.app.metadata[0].name : "No pods"
  value       = "http://localhost:${kubernetes_service.app.spec[0].port[0].node_port}"
}


output "secret_check" {
  description = "Verify that the secret is stored (base64 encoded)"
  value       = kubernetes_secret.app_secret.data["DB_PASSWORD"]
  sensitive   = true # Hides the value in the output
}

output "kubectl_logs" {
  description = "Command to view logs"
  value       = "kubectl logs -n ${var.namespace} -l app=${var.app_name}"
}