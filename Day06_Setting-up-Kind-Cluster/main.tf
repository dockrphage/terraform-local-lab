# main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# 1. Generate a unique ID for this run (helps avoid naming conflicts if you run multiple times)
resource "random_id" "cluster_id" {
  byte_length = 4
}

# 2. The "Create" Logic
resource "null_resource" "kind_cluster" {
  # Trigger recreation if vars change
  triggers = {
    cluster_name = var.cluster_name
    nodes        = var.nodes
    k8s_version  = var.kubernetes_version
  }

  # --- CREATE ---
  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating Kind cluster: ${var.cluster_name}-${random_id.cluster_id.hex}..."
      # Create a config file dynamically
      cat <<EOF > kind-config.yaml
      kind: Cluster
      apiVersion: kind.x-k8s.io/v1alpha4
      nodes:
      - role: control-plane
      ${join("\n", [for i in range(var.nodes) : "- role: worker"])}
      EOF
      
      kind create cluster --name ${var.cluster_name}-${random_id.cluster_id.hex} --config kind-config.yaml --image kindest/node:${var.kubernetes_version}
      echo "Cluster created successfully!"
    EOT
  }

  # --- DESTROY ---
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Destroying Kind cluster: ${var.cluster_name}-${random_id.cluster_id.hex}..."
      kind delete cluster --name ${var.cluster_name}-${random_id.cluster_id.hex}
      rm -f kind-config.yaml
      echo "Cluster destroyed."
    EOT
  }
}

# 3. Wait for kubectl to be ready (Optional but good practice)
# This ensures the cluster context is loaded before Terraform finishes
resource "null_resource" "wait_for_k8s" {
  depends_on = [null_resource.kind_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for cluster to be ready..."
      # Wait for at least 30 seconds for kubeconfig to settle
      sleep 30
      kubectl cluster-info
    EOT
  }
}