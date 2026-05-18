# outputs.tf

output "cluster_name" {
  description = "Full name of the created cluster"
  value       = "${var.cluster_name}-${random_id.cluster_id.hex}"
}

output "kubectl_context" {
  description = "The kubectl context name"
  value       = "${var.cluster_name}-${random_id.cluster_id.hex}"
}

output "nodes_info" {
  description = "List of nodes in the cluster"
  value = concat(
    ["control-plane"],
    [for i in range(var.nodes) : "worker-${i}"]
  )
}


# We need a local value to get node count (optional, but useful)
locals {
  nodes = var.nodes
}