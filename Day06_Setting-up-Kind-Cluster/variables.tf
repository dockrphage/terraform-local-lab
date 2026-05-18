# variables.tf

variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "terraform-lab"
}

variable "nodes" {
  description = "Number of worker nodes (control plane is always 1)"
  type        = number
  default     = 2
}

variable "kubernetes_version" {
  description = "K8s version (e.g., v1.28.0)"
  type        = string
  default     = "v1.28.0"
}