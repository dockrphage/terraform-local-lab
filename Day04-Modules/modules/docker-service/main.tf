terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

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

  command = var.command
  # restart = "unless-stopped"
  restart = "always"
}
