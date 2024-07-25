
module "networking" {
  source = "./modules/networking"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location


  vpc_cidrs                             = var.vpc_cidrs
  virtual_network_tags                  = var.virtual_network_tags
  aks_subnet_cidrs                      = var.aks_subnet_cidrs
  private_endpoint_storage_subnet_cidrs = var.private_endpoint_storage_subnet_cidrs
  azure_bastion_subnet_cidrs            = var.azure_bastion_subnet_cidrs
  vm_bastion_subnet_cidrs               = var.vm_bastion_subnet_cidrs
  database_subnet_cidrs                 = var.database_subnet_cidrs
  app_subnet_cidrs                      = var.app_subnet_cidrs
  app_gw_subnet_cidrs                   = var.app_gw_subnet_cidrs
  jumpbox_custom_data                   = var.jumpbox_custom_data
}

module "load_balancer" {
  source = "./modules/load_balancer"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  app_gw_subnet = module.networking.app_gw_subnet

  private_ip_address = var.gw_private_ip_address
}

module "database" {
  source = "./modules/database"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  database_subnet          = module.networking.database_subnet
  private_dns_zone_id      = module.networking.database_private_dns_zone_id
  database_username        = var.database_username
  database_name            = var.database_name
  postgresql_major_version = var.postgresql_major_version
}

module "identity" {
  source = "./modules/identity"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location
}

module "key_vault" {
  source = "./modules/key_vault"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  identity_object_id = module.identity.identity.principal_id
}

module "aks" {
  source = "./modules/aks"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  resource_group_id   = data.azurerm_resource_group.default.id
  location            = data.azurerm_resource_group.default.location

  aks_subnet            = module.networking.aks_subnet
  app_gw_subnet         = module.networking.app_gw_subnet
  gateway               = module.load_balancer.gateway
  identity              = module.identity.identity
  etcd_key_vault_key_id = module.key_vault.etcd_key_id

  max_pods             = var.max_pods
  node_pool_node_count = var.node_pool_node_count
  node_pool_vm_size    = var.node_pool_vm_size
  node_pool_name       = var.node_pool_name
  sku_tier             = var.aks_sku_tier
  service_cidr         = var.aks_service_cidr
  dns_service_ip       = var.aks_dns_service_ip
}
