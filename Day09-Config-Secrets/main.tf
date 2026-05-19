# main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "kubernetes" {
  config_context = "kind-config-lab"
} config_path    = "~/.kube/config"
  config_context = "kind-config-lab"
}
  # config_context = "kind-${var.app_name}" # Assuming cluster name matches app name or adjust as needed
  # If your cluster name is different, update this context. 
  # For simplicity, let's assume the cluster is 'terraform-lab' from Day 06.
  # We will use a dynamic lookup or default to 'terraform-lab' if not defined.
  # For this lab, let's hardcode the context to match Day 06 default for simplicity.
  # config_context = "kind-terraform-lab"
}

# 1. Create Namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
  }
}

# 2. Create ConfigMap (Non-sensitive data)
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    "MESSAGE" = var.message
    "APP_ENV" = "production"
  }
}

# 3. Create Secret (Sensitive data)
# Terraform automatically base64 encodes the values
resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "${var.app_name}-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    "DB_PASSWORD" = var.db_password
  }

  # Optional: Force encryption at rest if your cluster supports it
  type = "Opaque"
}

# 4. Deploy the Application
# We use a simple nginx image and a custom command to echo the env vars
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = "app-container"
          image = "nginx:latest"

          # Inject ConfigMap as Environment Variables
          env {
            name  = "MESSAGE"
            value = kubernetes_config_map.app_config.data["MESSAGE"]
          }
          
          # Inject Secret as Environment Variables
          env {
            name  = "DB_PASSWORD"
            value = kubernetes_secret.app_secret.data["DB_PASSWORD"]
          }

          # Simple command to show the env vars in the logs
          # (In a real app, this would be your app binary)
          command = ["/bin/sh", "-c"]
          args    = ["echo \"Message: $MESSAGE\"; echo \"Password (should be hidden): $DB_PASSWORD\"; nginx -g 'daemon off;'"]

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# 5. Expose with Service
resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.app_name}-svc"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "NodePort"
  }
}