# main.tf

# 1. Configure the Providers

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# 2. Create a Local File
resource "local_file" "greeting" {
  filename = "${path.module}/hello.txt"
  content  = var.local_file_content
}

# 3. Start a Docker Container
# Note: The docker provider automatically uses your local Docker daemon
resource "docker_container" "web_server" {
  image = var.container_image
  name  = "terraform-nginx-${random_id.server_id.hex}"
  
  # Map the container port to the host port
  ports {
    internal = var.container_port
    external = var.container_port
  }

  # Ensure the container restarts unless explicitly stopped
  restart = "unless-stopped"
}

# 4. Generate a random ID to make container names unique
resource "random_id" "server_id" {
  byte_length = 4
}