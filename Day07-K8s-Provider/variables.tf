# variables.tf

variable "cluster_name" {
  description = "Name of the Kind cluster to target"
  type        = string
  # default     = "terraform-lab" # Must match Day 06 default
}

variable "kube_context" {
  type = string
}