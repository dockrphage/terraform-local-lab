# variables.tf

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_monitoring" {
  description = "Whether to deploy the monitoring stack (Prometheus)"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of web server replicas"
  type        = number
  default     = 1
}