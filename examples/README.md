# Terraform Azure Datafold Examples

This directory contains examples demonstrating how to use the terraform-azure-datafold module with various configurations and customizations.

## Directory Structure

```
examples/
├── deployment/
│   ├── infra/          # Main infrastructure example
│   ├── application/    # Application deployment example  
│   └── templates/      # Template files
└── bootstrap/          # Bootstrap example
```

## Resource Name Overrides

The terraform-azure-datafold module provides 41 resource name override variables that allow you to customize resource names according to your organization's naming standards or compliance requirements.

### When to Use Overrides

- **Compliance Requirements**: Your organization has specific naming conventions
- **Environment Separation**: Different naming patterns for dev/staging/prod
- **Multi-tenant Deployments**: Unique identifiers for different customers/teams
- **Legacy System Integration**: Match existing resource naming patterns
- **Testing**: Short names for development/testing environments

## Storage Account Naming & Service Accounts

### The Problem

A common issue when using resource name overrides is inconsistency between:
1. `storage_account_name_override` in the module configuration
2. Storage account names referenced in service account role assignment scopes

This mismatch causes permission errors where service accounts try to access the wrong storage account.

### The Solution

The example in [examples/deployment/infra/main.tf](./deployment/infra/main.tf) uses a clean pattern:

```hcl
locals {
  # Set this to customize the storage account name, leave empty for default
  custom_storage_account_name = "" # Example: "prodacmest"

  # Computed storage account name (uses custom name if set, otherwise default)
  storage_account_name = local.custom_storage_account_name != "" ? local.custom_storage_account_name : replace("${local.deployment_name}-storage", "-", "")
}

module "azure" {
  # ... other configuration ...

  # When using custom storage account name, uncomment this:
  # storage_account_name_override = local.storage_account_name

  service_accounts = {
    "clickhouse" = {
      role_assignments = [
        {
          role  = "Storage Blob Data Contributor"
          # This automatically uses the same name as the override!
          scope = "/subscriptions/${local.azure_subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"
        }
      ]
    },
  }
}
```

### How It Works

1. **Single Source of Truth**: Set `custom_storage_account_name` in locals if you want a custom name
2. **Automatic Consistency**: Both the module override and service account scopes use `local.storage_account_name`
3. **No Mismatches**: Impossible to have different names in different places

### Usage Steps

1. **Default naming**: Leave `custom_storage_account_name = ""` and don't set any override
2. **Custom naming**: 
   - Set `custom_storage_account_name = "yourcustomname"`
   - Uncomment `storage_account_name_override = local.storage_account_name`
   - Service accounts automatically use the correct name

## Important Azure Constraints

### Storage Account Names
- **Maximum 24 characters**
- **Lowercase letters and numbers only**
- **Globally unique across Azure**

```hcl
# ✅ Good
custom_storage_account_name = replace("prod${substr(local.deployment_name, 0, 16)}st", "-", "")

# ❌ Bad - too long and contains hyphens
custom_storage_account_name = "production-${local.deployment_name}-storage-account"
```

### Key Vault Names
- **Maximum 24 characters**
- **Alphanumeric and hyphens only**
- **Globally unique across Azure**

### Azure Bastion Subnet
- **Must be exactly "AzureBastionSubnet"**
- This is an Azure requirement

## Best Practices

1. **Test First**: Always test override patterns in a development environment
2. **Be Consistent**: Use the same naming pattern across all resources
3. **Check Lengths**: Verify storage account and key vault names are ≤24 characters
4. **Document**: Include comments explaining your naming convention
5. **Verify**: Check Azure portal after deployment to ensure resources have expected names and permissions work
