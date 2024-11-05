locals {
  vpc_size = split("/", var.vpc_cidrs[0])[1]

  # Maps do not maintain order, so we need to create a list to track the order of subnets.
  # Only include ADLS in subnet order if create_adls is true
  base_subnet_order = [
    "aks",
    "private_endpoint_storage",
    "azure_bastion",
    "vm_bastion",
    "database",
    "app",
    "app_gw"
  ]
  subnet_order = var.create_adls ? concat(local.base_subnet_order, ["adls"]) : local.base_subnet_order

  # Determine which subnets need to be calculated, maintaining order
  subnets_to_calculate = [
    for subnet in local.subnet_order : {
      name = subnet
      needs_calculation = length(lookup({
        aks = var.aks_subnet_cidrs,
        private_endpoint_storage = var.private_endpoint_storage_subnet_cidrs,
        azure_bastion = var.azure_bastion_subnet_cidrs,
        vm_bastion = var.vm_bastion_subnet_cidrs,
        database = var.database_subnet_cidrs,
        app = var.app_subnet_cidrs,
        app_gw = var.app_gw_subnet_cidrs,
        adls = var.create_adls ? var.private_endpoint_adls_subnet_cidrs : ["dummy"]  # Only check ADLS if create_adls is true
      }, subnet)) == 0
    }
  ]

  # Create list of newbits only for subnets that need calculation
  subnet_newbits = [
    for subnet in local.subnets_to_calculate :
    subnet.needs_calculation ?
    local.vpc_size - ceil(log(lookup({
      aks = var.aks_subnet_size,
      private_endpoint_storage = var.private_endpoint_storage_subnet_size,
      azure_bastion = var.azure_bastion_subnet_size,
      vm_bastion = var.vm_bastion_subnet_size,
      database = var.database_subnet_size,
      app = var.app_subnet_size,
      app_gw = var.app_gw_subnet_size,
      adls = var.private_endpoint_adls_subnet_size
    }, subnet.name), 2)) : null
  ]

  # Remove null values
  filtered_newbits = compact(local.subnet_newbits)

  # Calculate only needed CIDRs
  calculated_cidrs = length(local.filtered_newbits) > 0 ? cidrsubnets(var.vpc_cidrs[0], local.filtered_newbits...) : []

  # Create a map to track which index to use for each subnet, based on position in filtered list
  calculated_index = {
    for idx, subnet in local.subnets_to_calculate :
    subnet.name => subnet.needs_calculation ? index(
      [for s in local.subnets_to_calculate : s.name if s.needs_calculation],
      subnet.name
    ) : null
  }

  # Final subnet CIDRs
  aks_subnet_cidrs = coalescelist(
    var.aks_subnet_cidrs,
    local.calculated_index.aks != null ? [local.calculated_cidrs[local.calculated_index.aks]] : []
  )
  private_endpoint_storage_subnet_cidrs = coalescelist(
    var.private_endpoint_storage_subnet_cidrs,
    local.calculated_index.private_endpoint_storage != null ? [local.calculated_cidrs[local.calculated_index.private_endpoint_storage]] : []
  )
  azure_bastion_subnet_cidrs = coalescelist(
    var.azure_bastion_subnet_cidrs,
    local.calculated_index.azure_bastion != null ? [local.calculated_cidrs[local.calculated_index.azure_bastion]] : []
  )
  vm_bastion_subnet_cidrs = coalescelist(
    var.vm_bastion_subnet_cidrs,
    local.calculated_index.vm_bastion != null ? [local.calculated_cidrs[local.calculated_index.vm_bastion]] : []
  )
  database_subnet_cidrs = coalescelist(
    var.database_subnet_cidrs,
    local.calculated_index.database != null ? [local.calculated_cidrs[local.calculated_index.database]] : []
  )
  app_subnet_cidrs = coalescelist(
    var.app_subnet_cidrs,
    local.calculated_index.app != null ? [local.calculated_cidrs[local.calculated_index.app]] : []
  )
  app_gw_subnet_cidrs = coalescelist(
    var.app_gw_subnet_cidrs,
    local.calculated_index.app_gw != null ? [local.calculated_cidrs[local.calculated_index.app_gw]] : []
  )
  # Only calculate ADLS subnet CIDR if create_adls is true
  private_endpoint_adls_subnet_cidrs = var.create_adls ? coalescelist(
    var.private_endpoint_adls_subnet_cidrs,
    local.calculated_index.adls != null ? [local.calculated_cidrs[local.calculated_index.adls]] : []
  ) : []
}


module "networking" {
  source = "./modules/networking"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  vpc_cidrs                             = var.vpc_cidrs
  virtual_network_tags                  = var.virtual_network_tags
  aks_subnet_cidrs                      = local.aks_subnet_cidrs
  private_endpoint_storage_subnet_cidrs = local.private_endpoint_storage_subnet_cidrs
  azure_bastion_subnet_cidrs            = local.azure_bastion_subnet_cidrs
  vm_bastion_subnet_cidrs               = local.vm_bastion_subnet_cidrs
  database_subnet_cidrs                 = local.database_subnet_cidrs
  app_subnet_cidrs                      = local.app_subnet_cidrs
  app_gw_subnet_cidrs                   = local.app_gw_subnet_cidrs
  private_endpoint_adls_subnet_cidrs    = local.private_endpoint_adls_subnet_cidrs
  jumpbox_custom_data                   = var.jumpbox_custom_data
  lb_is_public                          = var.lb_is_public
  k8s_public_access_cidrs               = var.k8s_public_access_cidrs
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

  identity = module.identity.identity

  domain_name = var.domain_name

  acme_provider = var.acme_provider
  acme_config   = var.acme_config
}

module "load_balancer" {
  source = "./modules/load_balancer"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  app_gw_subnet = module.networking.app_gw_subnet
  ssl_cert_id   = module.key_vault.ssl_cert_id
  public_ip     = var.lb_is_public ? module.networking.public_ip : null
  identity      = module.identity.identity

  private_ip_address = var.gw_private_ip_address
  domain_name        = var.domain_name
  ssl_cert_name      = var.ssl_cert_name
  lb_is_public       = var.lb_is_public
}

module "database" {
  count = var.create_database ? 1 : 0

  source = "./modules/database"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  database_subnet     = module.networking.database_subnet
  private_dns_zone_id = module.networking.database_private_dns_zone_id

  database_username              = var.database_username
  database_name                  = var.database_name
  database_sku                   = var.database_sku
  database_backup_retention_days = var.database_backup_retention_days
  database_storage_mb            = var.database_storage_mb
  postgresql_major_version       = var.postgresql_major_version
}

module "clickhouse_backup" {
  source = "./modules/clickhouse_backup"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  vpc                             = module.networking.vpc
  private_endpoint_storage_subnet = module.networking.private_endpoint_storage_subnet
  identity                        = module.identity.identity
}

module "data_lake" {
  source = "./modules/data_lake"
  count = var.create_adls ? 1 : 0

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  vpc                          = module.networking.vpc
  private_endpoint_adls_subnet = module.networking.private_endpoint_adls_subnet
  identity                     = module.identity.identity
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

  max_pods                = var.max_pods
  node_pool_node_count    = var.node_pool_node_count
  min_node_count          = var.min_node_count
  max_node_count          = var.max_node_count
  node_pool_vm_size       = var.node_pool_vm_size
  node_pool_name          = var.node_pool_name
  sku_tier                = var.aks_sku_tier
  service_cidr            = var.aks_service_cidr
  dns_service_ip          = var.aks_dns_service_ip
  custom_node_pools       = var.custom_node_pools
  private_cluster_enabled = var.private_cluster_enabled
  k8s_public_access_cidrs = var.k8s_public_access_cidrs
}
