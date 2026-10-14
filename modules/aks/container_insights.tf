# Container logs to Log Analytics through Container insights: the monitoring
# add-on (oms_agent on the cluster, main.tf) runs the Azure Monitor agent on
# every node, which tails each container's stdout into the ContainerLogV2 table,
# so applications log to stdout and need no collector or hostPath of their own.
#
# With managed identity auth (msi_auth_for_monitoring_enabled) the agent reads
# what to collect from a data collection rule associated with the cluster. The
# CLI and portal create that rule when they enable the add-on; Terraform does
# not, so it is created here, the same as Microsoft's Terraform template does
# (MSCI-<region>-<cluster>). The default streams are the portal's "Logs and
# Events" preset. The rule lives in the cluster's region, so an existing
# workspace passed in must be in that region too.
#
# Namespace filtering in the rule applies to the inventory and perf tables, not
# to container logs. Container logs are filtered in the cluster with the
# container-azm-ms-agentconfig ConfigMap; by default it already leaves out
# kube-system and the other system namespaces.

locals {
  container_insights_enabled = var.container_insights.enabled
  container_insights_workspace_id = !local.container_insights_enabled ? null : coalesce(
    var.container_insights.log_analytics_workspace_id,
    one(azurerm_log_analytics_workspace.container_insights[*].id),
  )
}

resource "azurerm_log_analytics_workspace" "container_insights" {
  count = local.container_insights_enabled && var.container_insights.log_analytics_workspace_id == null ? 1 : 0

  name                = "${var.deployment_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.container_insights.log_retention_days

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule" "container_insights" {
  count = local.container_insights_enabled ? 1 : 0

  name                = "MSCI-${var.location}-${local.cluster_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  description         = "Container insights log collection for ${local.cluster_name}"

  destinations {
    log_analytics {
      workspace_resource_id = local.container_insights_workspace_id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = var.container_insights.streams
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = var.container_insights.streams
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          enableContainerLogV2   = true
        }
      })
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "container_insights" {
  count = local.container_insights_enabled ? 1 : 0

  name                    = "ContainerInsightsExtension"
  target_resource_id      = azurerm_kubernetes_cluster.default.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights[0].id
  description             = "Association of container insights data collection rule. Deleting it stops log collection for this cluster."
}
