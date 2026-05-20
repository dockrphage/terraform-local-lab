# main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# 1. Configure the Kubernetes Provider
# It automatically reads ~/.kube/config
provider "kubernetes" {
  config_path    = "~/.kube/config"
  # config_context = "kind-${var.cluster_name}-${random_id.cluster_id.hex}" # Matches the context from Day 06
}

# 2. Define the Namespace (Best Practice)
resource "kubernetes_namespace" "lab" {
  metadata {
    name = "${var.cluster_name}-lab"
  }
}

# 3. Deploy a simple Pod (Hello World)
resource "kubernetes_pod" "hello" {
  metadata {
    name      = "hello-pod"
    namespace = kubernetes_namespace.lab.metadata[0].name
    labels = {
      app = "hello-world"
    }
  }

  spec {
    container {
      name  = "hello-container"
      image = "nginx:latest"

      port {
        container_port = 80
      }
    }
  }
}

# 4. Expose the Pod with a Service (ClusterIP)
resource "kubernetes_service" "hello-svc" {
  metadata {
    name      = "hello-service"
    namespace = kubernetes_namespace.lab.metadata[0].name
  }

  spec {
    selector = {
      app = "hello-world"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    # type = "ClusterIP" # Default, internal only
    type = "NodePort" # Exposes the service on each Node's IP at a random port
  }
}