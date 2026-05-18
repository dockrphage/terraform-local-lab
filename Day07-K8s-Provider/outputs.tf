output "namespace_name" {
  value = kubernetes_namespace.lab.metadata[0].name
}

#output "pod_ip" {
  #value = kubernetes_pod.hello.status[0].pod_ip
#}

output "service_cluster_ip" {
  description = "ClusterIP of the hello service"
  value       = kubernetes_service.hello-svc.spec[0].cluster_ip
}

output "kubectl_command" {
  value = "kubectl get pods -n ${kubernetes_namespace.lab.metadata[0].name}"
}
