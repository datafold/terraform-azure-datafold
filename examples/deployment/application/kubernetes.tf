data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.sops_file.infra.data["global.clusterName"]
  resource_group_name = local.resource_group_name
}
