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
    node_count                  = var.node_pool_node_count
    temporary_name_for_rotation = "rotating"
    vm_size                     = var.node_pool_vm_size
    vnet_subnet_id              = var.aks_subnet.id

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
    ]
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
