locals {
  default_unset_value = "notset"

  postgres = length(module.database) > 0 ? {
    database_name = module.database[0].postgres_database_name
    password      = module.database[0].postgres_password
    host          = module.database[0].postgres_host
    username      = module.database[0].postgres_username
  } : null

  blob_storage = {
    account_name = module.clickhouse_backup.azure_blob_account_name
    account_key  = module.clickhouse_backup.azure_blob_account_key
    container    = module.clickhouse_backup.azure_blob_container
  }

  adls = length(module.data_lake) > 0 ? {
    account_key  = module.data_lake[0].adls_account_key
    account_name = module.data_lake[0].adls_account_name
    filesystem   = module.data_lake[0].adls_filesystem
  } : null
}

# Cloud Provider Information
output "cloud_provider" {
  description = "The cloud provider being used (always 'azure' for this module)"
  value       = "azure"
}

# Network Information
output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.networking.vpc_cidr
}

output "load_balancer_ips" {
  description = "The public IP addresses assigned to the load balancer"
  value       = module.networking.public_ip.ip_address
}

# Domain Information
output "domain_name" {
  description = "The domain name configured for the deployment"
  value       = var.domain_name
}

# Cluster Information
output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.cluster_name
}

# Database Information
output "postgres_database_name" {
  description = "The name of the PostgreSQL database"
  value       = try(local.postgres.database_name, local.default_unset_value)
}

output "postgres_host" {
  description = "The hostname of the PostgreSQL server"
  value       = try(local.postgres.host, local.default_unset_value)
}

output "postgres_username" {
  description = "The username for PostgreSQL database access"
  value       = try(local.postgres.username, local.default_unset_value)
}

output "postgres_password" {
  description = "The password for PostgreSQL database access"
  value       = try(local.postgres.password, local.default_unset_value)
  sensitive   = true
}

# Azure Blob Storage Information
output "azure_blob_account_name" {
  description = "The name of the Azure Blob Storage account"
  value       = local.blob_storage.account_name
}

output "azure_blob_account_key" {
  description = "The access key for the Azure Blob Storage account"
  value       = local.blob_storage.account_key
  sensitive   = true
}

output "azure_blob_container" {
  description = "The name of the Azure Blob Storage container"
  value       = local.blob_storage.container
}

# ADLS Information
output "adls_account_name" {
  description = "The name of the Azure Data Lake Storage account"
  value       = try(local.adls.account_name, local.default_unset_value)
}

output "adls_account_key" {
  description = "The access key for the Azure Data Lake Storage account"
  value       = try(local.adls.account_key, local.default_unset_value)
  sensitive   = true
}

output "adls_filesystem" {
  description = "The filesystem details for the Azure Data Lake Storage"
  value       = try(local.adls.filesystem, local.default_unset_value)
}