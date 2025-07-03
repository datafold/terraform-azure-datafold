locals {
  cluster_name = "${var.deployment_name}-cluster"
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.deployment_name}-k8s"
  sku_tier            = var.sku_tier

  dynamic api_server_access_profile {
    for_each = var.private_cluster_enabled ? [] : [1]
    content {
      authorized_ip_ranges = var.k8s_public_access_cidrs
    }
  }

  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = true
  oidc_issuer_enabled                 = true
  workload_identity_enabled           = var.workload_identity_on

  ingress_application_gateway {
    gateway_id = var.gateway.id
  }

  storage_profile {
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  default_node_pool {
    max_pods                    = var.max_pods
    name                        = var.node_pool_name
    temporary_name_for_rotation = "rotating"
    vm_size                     = var.node_pool_vm_size
    vnet_subnet_id              = var.aks_subnet.id

    auto_scaling_enabled = true
    max_count            = var.max_node_count
    min_count            = var.min_node_count
    node_count           = var.node_pool_node_count

    upgrade_settings {
      max_surge = "10%" // Otherwise TF wants to set it back to `null`
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity.id]
  }

  # Note: Network is set to Azure CNI, which means that the pods will gain their IP from the VNET (aks_subnet)
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      microsoft_defender,
      default_node_pool[0].node_count,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "custom_node_pools" {
  for_each = { for pool in var.custom_node_pools : pool.name => pool if pool.enabled }

  # Name must begin with a lowercase letter, contain only lowercase letters and numbers and be between 1 and 12 characters in length
  name                  = replace(each.value.name, "-", "")
  kubernetes_cluster_id = azurerm_kubernetes_cluster.default.id
  vnet_subnet_id        = var.aks_subnet.id
  vm_size               = each.value.vm_size
  os_disk_type          = each.value.disk_type
  os_disk_size_gb       = each.value.disk_size_gb

  auto_scaling_enabled = true
  node_count           = each.value.initial_node_count
  min_count            = each.value.min_node_count
  max_count            = each.value.max_node_count
  eviction_policy      = each.value.spot ? "Delete" : null

  priority = each.value.spot ? "Spot" : "Regular"

  # Upgrade-specific settings if max_surge is defined. Spot pools can't set max surge
  dynamic "upgrade_settings" {
    for_each = each.value.max_surge != null ? [1] : []
    content {
      max_surge = each.value.max_surge
    }
  }

  node_taints = [
    for taint in each.value.taints : "${taint.key}=${taint.value}:${taint.effect}"
  ]
  node_labels = each.value.labels

  tags = var.tags

  lifecycle {
    ignore_changes = [ node_count ]
  }
}

locals {
  ingress_gateway_principal_id = azurerm_kubernetes_cluster.default.ingress_application_gateway.0.ingress_application_gateway_identity.0.object_id
}

resource "azurerm_role_assignment" "gateway" {
  depends_on           = [local.ingress_gateway_principal_id]
  scope                = var.gateway.id
  role_definition_name = "Contributor"
  principal_id         = local.ingress_gateway_principal_id
}

resource "azurerm_role_assignment" "resource_group" {
  scope                = azurerm_kubernetes_cluster.default.node_resource_group_id
  role_definition_name = "Reader"
  principal_id         = local.ingress_gateway_principal_id

  depends_on = [
    azurerm_kubernetes_cluster.default,
    local.ingress_gateway_principal_id
  ]
}

resource "azurerm_role_assignment" "app_gw_subnet" {
  depends_on           = [local.ingress_gateway_principal_id]
  scope                = var.app_gw_subnet.id
  role_definition_name = "Contributor"
  principal_id         = local.ingress_gateway_principal_id
}

data "azurerm_user_assigned_identity" "agic" {
  name                = "ingressapplicationgateway-${local.cluster_name}"
  resource_group_name = azurerm_kubernetes_cluster.default.node_resource_group
}

resource "azurerm_role_assignment" "agic_identity_operator" {
  depends_on           = [local.ingress_gateway_principal_id]
  scope                = var.identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = data.azurerm_user_assigned_identity.agic.principal_id
}

# Create managed identities only for service accounts that need them
resource "azurerm_user_assigned_identity" "workload_identities" {
  for_each = {
    for sa_name, sa_config in var.service_accounts : sa_name => sa_config
    if sa_config.create_azure_identity
  }

  name                = coalesce(each.value.identity_name, "${each.key}-identity")
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Purpose        = "AKS Workload Identity"
    ServiceAccount = each.key
    Namespace      = each.value.namespace
  }
}

# Create federated identity credentials
resource "azurerm_federated_identity_credential" "workload_credentials" {
  for_each = {
    for sa_name, sa_config in var.service_accounts : sa_name => sa_config
    if sa_config.create_azure_identity
  }

  name                = "${each.key}-federated-credential"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.default.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.workload_identities[each.key].id
  subject             = "system:serviceaccount:${each.value.namespace}:${each.key}"

  depends_on = [
    azurerm_kubernetes_cluster.default,
    azurerm_user_assigned_identity.workload_identities,
  ]
}

resource "azurerm_role_assignment" "workload_identity_roles" {
  for_each = {
    for assignment in flatten([
      for sa_name, sa_config in var.service_accounts : [
        for idx, role_assignment in sa_config.role_assignments : {
          key                = "${sa_name}-${idx}"
          service_account    = sa_name
          role_definition_name = role_assignment.role
          scope              = role_assignment.scope
          principal_id       = azurerm_user_assigned_identity.workload_identities[sa_name].principal_id
        }
      ] if sa_config.create_azure_identity && length(sa_config.role_assignments) > 0
    ]) : assignment.key => assignment
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id

  depends_on = [
    azurerm_user_assigned_identity.workload_identities
  ]
}
