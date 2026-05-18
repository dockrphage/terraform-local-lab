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

# 1. Provider Configuration (Same as Day 07)
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = var.kube_context
  }
}


# 2. Add the Prometheus Community Chart Repository
# We run this as a resource so it happens before the install
/* resource "helm_release" "prometheus_repo" {
  name = "prometheus-community"

  # repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "" # Empty chart name, just adds the repo
  
  # We don't actually "install" a chart here, just add the repo
  # But the resource ensures the repo is available for the next resource
} */

# 3. Deploy Prometheus (The Main Event)
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "prometheus-community"
  # repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "65.5.0" # Pin a specific version for stability

  # Create the namespace automatically
  namespace = "monitoring"
  create_namespace = true

  # Override default values to make it lighter for our local lab
  set {
    name  = "server.service.type"
    value = "NodePort" # Expose port 80 on the node
  }
  
  set {
    name  = "server.service.nodePort"
    value = "30090"    # Specific port for easy access
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = "false"    # Disable disk storage for speed in local lab
  }

  # Depend on the repo resource (though usually not strictly needed if repo URL is provided directly)
  # But good practice if you split the repo addition into a separate step later
  # depends_on = [helm_release.prometheus_repo]
}

# 4. Deploy Grafana (Bonus: Visualize the data)
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.0.0" # Pin version

  namespace = "monitoring"
  create_namespace = true

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "service.nodePort"
    value = "30300"
  }

  # Get the admin password from the secret (advanced output)
  set {
    name  = "adminPassword"
    value = "adminpassword"
  }
}