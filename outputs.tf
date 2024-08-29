output "cloud_provider" {
  value       = "azure"
  description = "A string describing the type of cloud provider to be passed onto the helm charts"
}

output "vpc_cidr" {
  value = module.networking.vpc_cidr
}

output "domain_name" {
  value = var.domain_name
}

output "cluster_name" {
  value = module.aks.cluster_name
}

output "load_balancer_ips" {
  value = module.networking.public_ip.ip_address
}

output "postgres_database_name" {
  value = module.database.postgres_database_name
}

output "postgres_password" {
  value = module.database.postgres_password
}

output "postgres_host" {
  value = module.database.postgres_host
}

output "postgres_username" {
  value = module.database.postgres_username
}
