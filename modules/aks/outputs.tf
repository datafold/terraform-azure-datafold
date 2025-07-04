output "cluster_name" {
  value = azurerm_kubernetes_cluster.default.name
}

output "service_account_configs" {
  description = "Configuration for each service account including Azure identity info"
  value = {
    for sa_name, sa_config in var.service_accounts : sa_name => {
      create_azure_identity = sa_config.create_azure_identity
      azure_identity = sa_config.create_azure_identity ? {
        client_id     = azurerm_user_assigned_identity.workload_identities[sa_name].client_id
        principal_id  = azurerm_user_assigned_identity.workload_identities[sa_name].principal_id
        resource_id   = azurerm_user_assigned_identity.workload_identities[sa_name].id
        identity_name = azurerm_user_assigned_identity.workload_identities[sa_name].name
      } : null
    }
  }
}

output "node_resource_group_id" {
  value = azurerm_kubernetes_cluster.default.node_resource_group
  description = "Auto-generated resource group with resources for managed cluster"
}
