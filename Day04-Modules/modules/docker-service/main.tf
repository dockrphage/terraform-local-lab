# modules/docker-service/main.tf

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

# We need a unique ID for the container name to avoid conflicts if re-run
resource "random_id" "id" {
  byte_length = 4
}

resource "docker_container" "service" {
  name  = "${var.name}-mod-${random_id.id.hex}"
  image = var.image

  dynamic "ports" {
  for_each = var.port > 0 ? [var.port] : []
  content {
    internal = ports.value
    external = ports.value
  }
}



  # Handle commands (like sleep for alpine)
  command = var.command
  
  restart = "unless-stopped"
}