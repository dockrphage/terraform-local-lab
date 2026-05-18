# variables.tf

variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "terraform-lab"
}
variable "kube_context" {
  type = string
}