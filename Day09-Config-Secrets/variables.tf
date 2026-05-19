# variables.tf

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "my-app"
}

variable "message" {
  description = "Message to display on the homepage"
  type        = string
  default     = "Hello from Terraform ConfigMap!"
}

variable "db_password" {
  description = "Database password (sensitive)"
  type        = string
  sensitive   = true # Tells Terraform to hide this in logs
  default     = "super-secret-password-123"
}

variable "namespace" {
  description = "Namespace to deploy into"
  type        = string
  default     = "config-lab"
}