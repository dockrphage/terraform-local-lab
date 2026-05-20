# variables.tf

variable "services" {
  description = "A map of services to deploy. Key = name, Value = config"
  type = map(object({
    image = string
    port  = number
  }))

  default = {
    web = {
      image = "nginx:latest"
      port  = 80
    }
    redis = {
      image = "redis:alpine"
      port  = 6379
    }
    alpine = {
      image = "alpine:latest"
      port  = 0 # Alpine doesn't expose a port by default, we'll skip mapping if 0
    }
    
  }
}