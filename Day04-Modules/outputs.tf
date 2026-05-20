# Day04-Modules/outputs.tf

output "web_ip" {
  description = "IP of the web server"
  value       = module.web_server.container_ip
}

output "redis_ip" {
  description = "IP of the redis server"
  value       = module.cache_server.container_ip
}

output "all_names" {
  description = "Names of all containers"
  value = [
    module.web_server.container_name,
    module.cache_server.container_name,
    module.worker.container_name
  ]
}
