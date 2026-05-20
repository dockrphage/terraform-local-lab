# outputs.tf

output "namespace_name" {
  value = kubernetes_namespace.lab.metadata[0].name
}

output "pod_ip" {
  # value = kubernetes_pod.hello.status.pod_ip
  value = "Pod IP not available from resource"
}

output "service_cluster_ip" {
  # value = kubernetes_service.hello-svc.status.load_balancer.ingress.ip # Might be empty for ClusterIP
  # Better for ClusterIP:
  value = kubernetes_service.hello-svc.spec[0].cluster_ip
}

output "kubectl_command" {
  value = "kubectl get pods -n ${kubernetes_namespace.lab.metadata[0].name}"
  
}