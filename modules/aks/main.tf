resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.deployment_name}-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.deployment_name}-k8s"
  sku_tier            = var.sku_tier

  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true

  ingress_application_gateway {
    gateway_id = var.gateway.id
  }

  default_node_pool {
    max_pods                    = var.max_pods
    name                        = var.node_pool_name
    temporary_name_for_rotation = "rotating"
    vm_size                     = var.node_pool_vm_size
    vnet_subnet_id              = var.aks_subnet.id

    enable_auto_scaling = true
    max_count           = var.max_node_count
    min_count           = var.min_node_count
    node_count          = var.node_pool_node_count

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
      oidc_issuer_enabled,
      oidc_issuer_url,
      workload_identity_enabled,
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

  enable_auto_scaling = true
  node_count          = each.value.initial_node_count
  min_count           = each.value.min_node_count
  max_count           = each.value.max_node_count
  eviction_policy     = each.value.spot ? "Delete" : null

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

  tags = var.tags
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
  depends_on           = [local.ingress_gateway_principal_id]
  scope                = var.resource_group_id
  role_definition_name = "Reader"
  principal_id         = local.ingress_gateway_principal_id
}

resource "azurerm_role_assignment" "app_gw_subnet" {
  depends_on           = [local.ingress_gateway_principal_id]
  scope                = var.app_gw_subnet.id
  role_definition_name = "Contributor"
  principal_id         = local.ingress_gateway_principal_id
}
