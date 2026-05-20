# Day04-Modules/main.tf

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

# We need a random ID for the module naming prefix
resource "random_id" "prefix" {
  byte_length = 4
}

# --- Module 1: Nginx Web Server ---
module "web_server" {
  source = "./modules/docker-service"

  name  = "web"
  image = "nginx:latest"
  port  = 80
}

# --- Module 2: Redis Cache ---
module "cache_server" {
  source = "./modules/docker-service"

  name  = "redis"
  image = "redis:alpine"
  port  = 6379
}

# --- Module 3: Alpine (Worker) ---
module "worker" {
  source = "./modules/docker-service"

  name    = "worker"
  image   = "alpine:latest"
  port    = 0
  command = ["sleep", "3600"]
}
