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

# We still need a random ID for unique naming
resource "random_id" "server_id" {
  byte_length = 4
}

# THE LOOP: Create a container for every item in var.services
resource "docker_container" "multi_service" {
  # Loop through the map: for_each = var.services
  for_each = var.services

  # Use the key (e.g., "web", "redis") for the container name
  name  = "${each.key}-terraform-${random_id.server_id.hex}"
  
  image = each.value.image
  dynamic "ports" {
    # Only map ports if the port is greater than 0 (skip alpine)
    for_each = each.value.port > 0 ? [each.value.port] : []
    content {
        internal = ports.value
        external = ports.value
        }
  }

  # Optional: Keep them running
  restart = "unless-stopped"
  
  # For alpine, run a command so it doesn't exit immediately
  command = each.key == "alpine" ? ["sleep", "3600"] : null
}