# main.tf

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

resource "random_id" "env_id" {
  byte_length = 4
}

# --- Resource 1: Web Servers (Dynamic Replicas) ---
# If replica_count is 3, this creates 3 containers. If 1, it creates 1.
resource "docker_container" "web_server" {
  count = var.replica_count
  
  name  = "web-${var.environment}-${random_id.env_id.hex}-${count.index}"
  image = "nginx:latest"
  
  ports {
    internal = 80
    external = 8080 + count.index # Port 8080, 8081, etc.
  }

  restart = "unless-stopped"
}

# --- Resource 2: Monitoring (Conditional) ---
# We use a conditional expression: (var.enable_monitoring ?  : [])
# If true -> count = 1 (creates 1 container)
# If false -> count = [] (creates 0 containers)
resource "docker_container" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  name  = "prometheus-${var.environment}-${random_id.env_id.hex}"
  image = "prom/prometheus:latest"
  
  ports {
    internal = 9090
    external = 9090
  }

  # Pass environment as an argument to the container
  command = ["--config.file=/etc/prometheus/prometheus.yml"]
  
  restart = "unless-stopped"
}

# --- Resource 3: Optional Firewall (Another Example) ---
# Let's say we only want a "firewall" container if the environment is 'prod'
resource "docker_container" "firewall" {
  # Only create if environment is "prod"
  count = var.environment == "prod" ? 1 : 0

  name  = "firewall-${var.environment}-${random_id.env_id.hex}"
  image = "alpine:latest"
  command = ["sleep", "3600"]
  
  restart = "unless-stopped"
}