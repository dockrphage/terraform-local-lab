# variables.tf

variable "container_image" {
  description = "The Docker image to run"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "The port to expose for the container"
  type        = number
  default     = 80
}

variable "local_file_content" {
  description = "Content to write to the local file"
  type        = string
  default     = "My Terraform Lab is working!"
}