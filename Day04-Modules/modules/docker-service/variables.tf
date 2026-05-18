# modules/docker-service/variables.tf

variable "name" {
  description = "The name of the container"
  type        = string
}

variable "image" {
  description = "The Docker image to use"
  type        = string
}

variable "port" {
  description = "The port to expose (0 if none)"
  type        = number
  default     = 0
}

variable "command" {
  description = "Optional command to run (e.g., sleep for alpine)"
  type        = list(string)
  default     = null
}
