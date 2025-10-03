#  ┏┳┓┏━┓╻┏┓╻
#  ┃┃┃┣━┫┃┃┗┫
#  ╹ ╹╹ ╹╹╹ ╹


# ┏━┓╺━┓╻ ╻┏━┓┏━╸
# ┣━┫┏━┛┃ ┃┣┳┛┣╸
# ╹ ╹┗━╸┗━┛╹┗╸┗━╸

locals {
  # ╭─────────────────────────────────────────────────────────╮
  # │               STORAGE ACCOUNT NAMING                   │
  # ╰─────────────────────────────────────────────────────────╯
  #
  # Configure storage account name here. This same name will be used for:
  # 1. storage_account_name_override in the module (if custom_storage_account_name is set)
  # 2. Service account role assignment scopes - relies on pre-defined pattern
  #
  # This ensures consistency and prevents mismatched references.

  # Set this to customize the storage account name, leave empty for default
  custom_storage_account_name = "" # Example: replace("custom${substr(local.deployment_name, 0, 15)}st", "-", "")

  # Computed storage account name (uses custom name if set, otherwise default pattern)
  storage_account_name = local.custom_storage_account_name != "" ? local.custom_storage_account_name : replace("${local.deployment_name}-storage", "-", "")
}

module "azure" {
  source  = "datafold/datafold/azure"
  version = "1.0.0"

  providers = {
    azurerm = azurerm
    acme    = acme
  }

  # Common
  deployment_name     = local.deployment_name
  resource_group_name = local.resource_group_name
  environment         = local.environment

  # Provider
  location = local.provider_region

  # Network
  vpc_cidrs           = ["10.0.0.0/16"]  # Choose to align with your IP plan
  jumpbox_custom_data = filebase64("./../templates/datafold/cloud-init.txt")
  domain_name         = local.domain_name

  # Load Balancer
  ssl_cert_name = local.ssl_cert_name

  # Kubernetes
  k8s_public_access_cidrs = ["0.0.0.0/0"]  # Configure based on your security requirements

  # Nodes
  node_pool_vm_size = "Standard_E8s_v3"
  
  # For larger deployments, you can configure additional node pools
  # node_pool_vm_size_2 = "Standard_D4s_v3"
  # node_pool_min_count_2 = 0
  # node_pool_max_count_2 = 1

  service_accounts = {
    "${local.clickhouse_backup_sa}" = {
      namespace             = local.deployment_name
      create_azure_identity = true
      identity_name         = local.clickhouse_backup_sa
      role_assignments = [
        {
          role  = "Storage Blob Data Contributor"
          scope = "/subscriptions/${local.azure_subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"
        }
      ]
    },
  }

  # Certificate note
  # Example:
  # [profile acme]
  # role_arn = arn:aws:iam::1234567890:role/ACMERoute53CertificateChallenger
  # source_profile = default
  # region = us-west-2

  acme_provider = "route53"
  acme_config = {
    AWS_PROFILE = "acme"
  }

  # ╭─────────────────────────────────────────────────────────╮
  # │             RESOURCE NAME OVERRIDES                    │
  # ╰─────────────────────────────────────────────────────────╯
  #
  # This module provides 41 resource name override variables (not including
  # resource group, which is set directly in the module call above).
  #
  # By default, resources are named using the deployment_name and logical suffixes.
  # Use these overrides to customize resource names for compliance or naming standards.
  #
  # IMPORTANT NOTES:
  # - Azure storage account names: max 24 chars, lowercase letters/numbers only
  # - Key vault names: max 24 chars, alphanumeric and hyphens only
  # - AzureBastionSubnet: must be exactly this name per Azure requirements
  # - When using overrides, ensure service account scopes reference correct names
  # - Resource Group: Set resource_group_name directly, no override needed

  # ┌─────────────────────────────────────────────────────────┐
  # │                ROOT LEVEL RESOURCES                     │
  # └─────────────────────────────────────────────────────────┘

  # Uncomment and modify these to override root-level resource names:

  # clickhouse_data_disk_name_override       = "custom-${local.deployment_name}-ch-data"
  # clickhouse_logs_disk_name_override       = "custom-${local.deployment_name}-ch-logs"
  # redis_data_disk_name_override           = "custom-${local.deployment_name}-redis"

  # ┌─────────────────────────────────────────────────────────┐
  # │                  IDENTITY MODULE                        │
  # └─────────────────────────────────────────────────────────┘

  # identity_name_override = "custom-${local.deployment_name}-identity"

  # ┌─────────────────────────────────────────────────────────┐
  # │                    AKS MODULE                           │
  # └─────────────────────────────────────────────────────────┘

  # aks_cluster_name_override = "custom-${local.deployment_name}-aks"
  # aks_dns_prefix_override   = "custom-${local.deployment_name}-k8s"

  # ┌─────────────────────────────────────────────────────────┐
  # │                 DATABASE MODULE                         │
  # └─────────────────────────────────────────────────────────┘

  # postgresql_server_name_override   = "custom-${local.deployment_name}-pg-server"
  # postgresql_database_name_override = "custom_database_name"

  # ┌─────────────────────────────────────────────────────────┐
  # │              DATA LAKE MODULE (ADLS)                   │
  # └─────────────────────────────────────────────────────────┘
  # Note: Only applies when create_adls = true

  # adls_storage_account_name_override     = replace("custom${substr(local.deployment_name, 0, 15)}adls", "-", "")
  # adls_filesystem_name_override          = "custom-filesystem"
  # adls_private_dns_zone_name_override    = "custom.privatelink.dfs.core.windows.net"
  # adls_dns_link_name_override            = "custom-${local.deployment_name}-adls-link"
  # adls_private_endpoint_name_override    = "custom-${local.deployment_name}-adls-pe"

  # ┌─────────────────────────────────────────────────────────┐
  # │            CLICKHOUSE BACKUP MODULE                    │
  # └─────────────────────────────────────────────────────────┘
  
  # NOTE: When using custom_storage_account_name above, uncomment this line:
  # storage_account_name_override = local.storage_account_name
  
  # clickhouse_backup_container_name_override    = "custom-${local.deployment_name}-ch-backup"
  # storage_private_dns_zone_name_override      = "custom.privatelink.blob.core.windows.net"
  # storage_private_endpoint_name_override       = "custom-${local.deployment_name}-storage-pe"
  # storage_dns_link_name_override              = "custom-${local.deployment_name}-storage-link"

  # ┌─────────────────────────────────────────────────────────┐
  # │                KEY VAULT MODULE                         │
  # └─────────────────────────────────────────────────────────┘

  # key_vault_name_override           = "custom-${substr(local.deployment_name, 0, 14)}-kv"  # 24 char limit
  # etcd_key_name_override           = "custom-etcd-key"
  # ssl_certificate_name_override    = "custom-${local.deployment_name}-ssl"

  # ┌─────────────────────────────────────────────────────────┐
  # │              LOAD BALANCER MODULE                       │
  # └─────────────────────────────────────────────────────────┘

  # application_gateway_name_override = "custom-${local.deployment_name}-ag"

  # ┌─────────────────────────────────────────────────────────┐
  # │              NETWORKING MODULE                          │
  # └─────────────────────────────────────────────────────────┘

  # Virtual Network and Subnets
  # virtual_network_name_override                   = "custom-${local.deployment_name}-vnet"
  # aks_subnet_name_override                        = "custom-aks-subnet"
  # private_endpoint_storage_subnet_name_override   = "custom-pe-storage"
  # private_endpoint_adls_subnet_name_override      = "custom-pe-adls"
  # azure_bastion_subnet_name_override              = "AzureBastionSubnet"  # Must be exact name
  # vm_bastion_subnet_name_override                 = "custom-vm-bastion"
  # database_subnet_name_override                   = "custom-database-subnet"
  # app_subnet_name_override                        = "custom-app-subnet"
  # app_gw_subnet_name_override                     = "custom-appgw-subnet"

  # Public IPs
  # public_ip_name_override         = "custom-${local.deployment_name}-public-ip"
  # jumpbox_public_ip_name_override = "custom-${local.deployment_name}-jumpbox-ip"
  # bastion_public_ip_name_override = "custom-${local.deployment_name}-bastion-ip"

  # Network Security Groups
  # vnet_nsg_name_override    = "custom-${local.deployment_name}-vnet-nsg"
  # jumpbox_nsg_name_override = "custom-${local.deployment_name}-jumpbox-nsg"

  # Bastion and VM Resources
  # bastion_host_name_override = "custom-bastion"
  # vm_nic_name_override       = "custom-vm-nic"
  # linux_vm_name_override    = "custom-${local.deployment_name}-vm"

  # Database DNS Resources
  # database_private_dns_zone_name_override = "custom-${local.deployment_name}.postgres.database.azure.com"
  # database_dns_link_name_override         = "custom-${local.deployment_name}-db-link"
}
