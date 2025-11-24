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

  # Resource name overrides
  virtual_network_name_override                     = var.virtual_network_name_override
  aks_subnet_name_override                          = var.aks_subnet_name_override
  private_endpoint_storage_subnet_name_override     = var.private_endpoint_storage_subnet_name_override
  private_endpoint_adls_subnet_name_override        = var.private_endpoint_adls_subnet_name_override
  azure_bastion_subnet_name_override                = var.azure_bastion_subnet_name_override
  vm_bastion_subnet_name_override                   = var.vm_bastion_subnet_name_override
  database_subnet_name_override                     = var.database_subnet_name_override
  app_subnet_name_override                          = var.app_subnet_name_override
  app_gw_subnet_name_override                       = var.app_gw_subnet_name_override
  public_ip_name_override                           = var.public_ip_name_override
  jumpbox_public_ip_name_override                   = var.jumpbox_public_ip_name_override
  bastion_public_ip_name_override                   = var.bastion_public_ip_name_override
  vnet_nsg_name_override                            = var.vnet_nsg_name_override
  jumpbox_nsg_name_override                         = var.jumpbox_nsg_name_override
  bastion_host_name_override                        = var.bastion_host_name_override
  vm_nic_name_override                              = var.vm_nic_name_override
  linux_vm_name_override                            = var.linux_vm_name_override
  database_private_dns_zone_name_override          = var.database_private_dns_zone_name_override
  database_dns_link_name_override                  = var.database_dns_link_name_override
}

module "identity" {
  source = "./modules/identity"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  # Resource name overrides
  identity_name_override = var.identity_name_override
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

  # Resource name overrides
  key_vault_name_override       = var.key_vault_name_override
  etcd_key_name_override        = var.etcd_key_name_override
  ssl_certificate_name_override = var.ssl_certificate_name_override
}

module "load_balancer" {
  count = var.deploy_lb ? 1 : 0

  source = "./modules/load_balancer"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  app_gw_subnet = module.networking.app_gw_subnet
  ssl_cert_id   = module.key_vault.ssl_cert_id
  public_ip_id  = var.lb_is_public ? module.networking.public_ip_id : null
  public_ip     = module.networking.public_ip
  identity      = module.identity.identity

  private_ip_address = var.gw_private_ip_address
  domain_name        = var.domain_name
  ssl_cert_name      = var.ssl_cert_name
  lb_is_public       = var.lb_is_public

  # Resource name overrides
  application_gateway_name_override = var.application_gateway_name_override
}

module "database" {
  count = var.create_database ? 1 : 0

  source = "./modules/database"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  database_subnet     = module.networking.database_subnet
  private_dns_zone_id = module.networking.database_private_dns_zone_id

  # Existing database configuration
  use_existing_database                = var.use_existing_database
  existing_resource_group_name         = var.existing_database_resource_group_name
  existing_postgresql_server_name      = var.existing_postgresql_server_name
  existing_postgresql_database_name    = var.existing_postgresql_database_name

  # VNet peering and private endpoint configuration
  existing_vnet_resource_group_name    = var.existing_vnet_resource_group_name
  existing_vnet_name                   = var.existing_vnet_name
  existing_database_subnet_name        = var.existing_database_subnet_name
  existing_private_dns_zone_name       = var.existing_private_dns_zone_name
  our_vnet_id                          = module.networking.vpc.id
  our_vnet_name                        = module.networking.vpc.name
  our_private_endpoint_subnet_id       = module.networking.private_endpoint_storage_subnet.id

  database_username              = var.database_username
  database_name                  = var.database_name
  database_sku                   = var.database_sku
  database_backup_retention_days = var.database_backup_retention_days
  database_storage_mb            = var.database_storage_mb
  postgresql_major_version       = var.postgresql_major_version

  # Resource name overrides
  postgresql_server_name_override          = var.postgresql_server_name_override
  postgresql_database_name_override        = var.postgresql_database_name_override
  postgresql_private_endpoint_name_override = var.postgresql_private_endpoint_name_override
  postgresql_vnet_peering_name_prefix_override = var.postgresql_vnet_peering_name_prefix_override
}

module "clickhouse_backup" {
  source = "./modules/clickhouse_backup"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  location            = data.azurerm_resource_group.default.location

  vpc                             = module.networking.vpc
  private_endpoint_storage_subnet = module.networking.private_endpoint_storage_subnet
  identity                        = module.identity.identity

  # Resource name overrides
  storage_account_name_override           = var.storage_account_name_override
  clickhouse_backup_container_name_override = var.clickhouse_backup_container_name_override
  storage_private_dns_zone_name_override = var.storage_private_dns_zone_name_override
  storage_private_endpoint_name_override  = var.storage_private_endpoint_name_override
  storage_dns_link_name_override          = var.storage_dns_link_name_override
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

  # Resource name overrides
  adls_storage_account_name_override     = var.adls_storage_account_name_override
  adls_filesystem_name_override          = var.adls_filesystem_name_override
  adls_private_dns_zone_name_override    = var.adls_private_dns_zone_name_override
  adls_dns_link_name_override            = var.adls_dns_link_name_override
  adls_private_endpoint_name_override    = var.adls_private_endpoint_name_override
}

module "aks" {
  source = "./modules/aks"

  deployment_name     = var.deployment_name
  resource_group_name = data.azurerm_resource_group.default.name
  resource_group_id   = data.azurerm_resource_group.default.id
  location            = data.azurerm_resource_group.default.location

  aks_subnet            = module.networking.aks_subnet
  app_gw_subnet         = module.networking.app_gw_subnet
  gateway               = var.deploy_lb ? module.load_balancer[0].gateway : null
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
  workload_identity_on    = var.aks_workload_identity_enabled
  service_accounts        = var.service_accounts

  # Resource name overrides
  aks_cluster_name_override = var.aks_cluster_name_override
  aks_dns_prefix_override   = var.aks_dns_prefix_override
}

locals {
  clickhouse_data_disk_name = var.clickhouse_data_disk_name_override != "" ? var.clickhouse_data_disk_name_override : "${var.deployment_name}-clickhouse-data"
  clickhouse_logs_disk_name = var.clickhouse_logs_disk_name_override != "" ? var.clickhouse_logs_disk_name_override : "${var.deployment_name}-clickhouse-logs"
  redis_data_disk_name      = var.redis_data_disk_name_override != "" ? var.redis_data_disk_name_override : "${var.deployment_name}-redis-data"
}

resource "azurerm_managed_disk" "clickhouse_data" {
  name                 = local.clickhouse_data_disk_name
  location             = var.location
  resource_group_name  = module.aks.node_resource_group_id
  storage_account_type = var.disk_sku
  create_option        = "Empty"
  disk_size_gb         = var.clickhouse_data_size

  # Configure performance tier for Premium/Ultra disks
  disk_iops_read_write   = var.disk_sku == "Premium_LRS" || var.disk_sku == "UltraSSD_LRS" ? var.ch_data_disk_iops : null
  disk_mbps_read_write   = var.disk_sku == "Premium_LRS" || var.disk_sku == "UltraSSD_LRS" ? var.ch_data_disk_throughput : null

  # Ultra SSD specific settings
  disk_iops_read_only    = var.disk_sku == "UltraSSD_LRS" ? var.ch_data_disk_iops : null
  disk_mbps_read_only    = var.disk_sku == "UltraSSD_LRS" ? var.ch_data_disk_throughput : null

  tags = {
    Name = local.clickhouse_data_disk_name
  }

  depends_on = [
    module.aks
  ]
}

resource "azurerm_managed_disk" "clickhouse_logs" {
  name                 = local.clickhouse_logs_disk_name
  location             = var.location
  resource_group_name  = module.aks.node_resource_group_id
  storage_account_type = var.disk_sku
  create_option        = "Empty"
  disk_size_gb         = var.clickhouse_logs_size

  # Configure performance tier for Premium/Ultra disks
  disk_iops_read_write   = var.disk_sku == "Premium_LRS" || var.disk_sku == "UltraSSD_LRS" ? var.ch_logs_disk_iops : null
  disk_mbps_read_write   = var.disk_sku == "Premium_LRS" || var.disk_sku == "UltraSSD_LRS" ? var.ch_logs_disk_throughput : null

  # Ultra SSD specific settings
  disk_iops_read_only    = var.disk_sku == "UltraSSD_LRS" ? var.ch_logs_disk_iops : null
  disk_mbps_read_only    = var.disk_sku == "UltraSSD_LRS" ? var.ch_logs_disk_throughput : null

  tags = {
    Name = local.clickhouse_logs_disk_name
  }

  depends_on = [
    module.aks
  ]
}

resource "azurerm_managed_disk" "redis_data" {
  name                 = local.redis_data_disk_name
  location             = var.location
  resource_group_name  = module.aks.node_resource_group_id
  storage_account_type = var.disk_sku
  create_option        = "Empty"
  disk_size_gb         = var.redis_data_size

  # Configure performance tier for Premium/Ultra disks
  disk_iops_read_write   = var.disk_sku == "Premium_LRS" || var.disk_sku == "UltraSSD_LRS" ? var.redis_disk_iops : null
  disk_mbps_read_write   = var.disk_sku == "Premium_LRS" || var.disk_sku == "UltraSSD_LRS" ? var.redis_disk_throughput : null

  # Ultra SSD specific settings
  disk_iops_read_only    = var.disk_sku == "UltraSSD_LRS" ? var.redis_disk_iops : null
  disk_mbps_read_only    = var.disk_sku == "UltraSSD_LRS" ? var.redis_disk_throughput : null

  tags = {
    Name = local.redis_data_disk_name
  }

  depends_on = [
    module.aks
  ]
}