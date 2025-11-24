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
    "datafold-clickhouse" = {
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

## Using Existing PostgreSQL Database

The module supports using an existing PostgreSQL database instead of creating a new one. This is useful when:

- You have a shared database server across multiple environments
- You want to use a centrally managed database instance
- The database exists in a different resource group or subscription

### Configuration

To use an existing database, set the following variables:

```hcl
module "azure" {
  # ... other configuration ...

  # Enable database module but use existing database
  create_database       = true
  use_existing_database = true

  # Specify the existing database details
  existing_database_resource_group_name = "my-database-rg"
  existing_postgresql_server_name       = "my-postgres-server"
  existing_postgresql_database_name     = "datafold"
}
```

### Important Notes

1. **Authentication**: The module cannot access the password for existing databases. You'll need to manage authentication separately.

2. **Resource Group**: The existing database can be in a different resource group that this module doesn't manage.

3. **Networking**: Ensure the AKS cluster can reach the existing database (proper networking, firewall rules, etc.).

4. **Validation**: All three existing database variables must be provided when `use_existing_database = true`.

### Example

```hcl
locals {
  # Use existing database in production, create new in dev
  use_existing_db = var.environment == "production"
}

module "azure" {
  source = "path/to/terraform-azure-datafold"

  deployment_name = "my-app-${var.environment}"
  
  # Database configuration
  create_database       = true
  use_existing_database = local.use_existing_db

  # Existing database details (only used when use_existing_database = true)
  existing_database_resource_group_name = local.use_existing_db ? "production-shared-db-rg" : ""
  existing_postgresql_server_name       = local.use_existing_db ? "prod-postgres-shared" : ""
  existing_postgresql_database_name     = local.use_existing_db ? "datafold_prod" : ""

  # Other configuration...
}
```

## VNet Peering for Cross-VNet Database Access

When your existing PostgreSQL database is located in a different VNet (possibly in a different resource group), the module can automatically set up VNet peering and private endpoints to enable secure connectivity.

### Scenario

This is useful when:
- Your PostgreSQL database is in a centralized "shared services" VNet
- The database VNet is managed by a different team or in a different subscription
- You need private, secure connectivity without exposing the database publicly
- You want to maintain network isolation while enabling cross-VNet access

### Configuration

In addition to the basic existing database configuration, you need to specify the VNet details:

```hcl
module "azure" {
  source = "path/to/terraform-azure-datafold"

  # ... other configuration ...

  # Basic existing database configuration
  create_database       = true
  use_existing_database = true
  
  existing_database_resource_group_name = "shared-services-rg"
  existing_postgresql_server_name       = "shared-postgres-01"
  existing_postgresql_database_name     = "datafold_app"

  # VNet peering configuration (required when database is in different VNet)
  existing_vnet_resource_group_name = "shared-services-network-rg"
  existing_vnet_name                = "shared-services-vnet"
  existing_database_subnet_name     = "database-subnet"
  
  # Optional: Specify existing private DNS zone name (defaults to standard PostgreSQL private link zone)
  # existing_private_dns_zone_name = "privatelink.postgres.database.azure.com"
}
```

### What Gets Created

When using existing database with VNet peering, the module automatically creates:

1. **Bidirectional VNet Peering**:
   - Peering from your VNet to the existing VNet
   - Peering from the existing VNet back to your VNet

2. **Private DNS Integration**:
   - Uses the existing private DNS zone that comes with the existing PostgreSQL server
   - Links our VNet to the existing private DNS zone for proper name resolution

3. **Private Endpoint**:
   - Created in your VNet's private endpoint subnet
   - Points to the existing PostgreSQL server
   - Automatically integrated with the existing private DNS zone

### Network Flow

```
Your VNet ←→ VNet Peering ←→ Existing VNet
    ↓                              ↓
Private Endpoint  ←---→  PostgreSQL Server
    ↓                              ↓
Existing Private DNS Zone ←-------+
(resolves to private IP)
```

### Prerequisites

1. **Permissions**: You need contributor access to both resource groups:
   - Your resource group (for creating resources)
   - Existing VNet resource group (for creating peering)

2. **No Overlapping CIDRs**: Your VNet CIDR must not overlap with the existing VNet CIDR

3. **PostgreSQL Server**: Must support private endpoints (Azure PostgreSQL Flexible Server) and should already have private DNS integration configured

### Complete Example

```hcl
locals {
  environment = "production"
  
  # Production uses shared database, other environments create their own
  use_shared_db = local.environment == "production"
}

module "azure" {
  source = "path/to/terraform-azure-datafold"

  deployment_name = "datafold-${local.environment}"
  location        = "East US"
  
  # VNet configuration - ensure no CIDR overlap with shared services VNet
  vpc_cidrs = ["10.2.0.0/16"]  # Shared services uses 10.1.0.0/16

  # Database configuration
  create_database       = true
  use_existing_database = local.use_shared_db

  # Existing database configuration (production only)
  existing_database_resource_group_name = local.use_shared_db ? "shared-services-rg" : ""
  existing_postgresql_server_name       = local.use_shared_db ? "prod-postgres-shared" : ""
  existing_postgresql_database_name     = local.use_shared_db ? "datafold_prod" : ""

  # VNet peering configuration (production only)
  existing_vnet_resource_group_name = local.use_shared_db ? "shared-services-network-rg" : ""
  existing_vnet_name                = local.use_shared_db ? "shared-services-vnet" : ""
  existing_database_subnet_name     = local.use_shared_db ? "postgres-subnet" : ""
  existing_private_dns_zone_name    = local.use_shared_db ? "privatelink.postgres.database.azure.com" : ""

  # Other configuration...
  domain_name = "datafold-${local.environment}.company.com"
  # ... rest of your configuration
}

# Access the connection details
output "postgres_connection" {
  value = {
    host     = module.azure.postgres_host          # Resolves to private endpoint when using existing DB
    database = module.azure.postgres_database_name
    username = module.azure.postgres_username
    # Note: password not available for existing databases
  }
  sensitive = true
}
```

### Troubleshooting

1. **VNet Peering Issues**: Ensure both VNets allow peering and have proper routing
2. **DNS Resolution**: Verify private DNS zone is linked to both VNets
3. **Private Endpoint**: Check that the endpoint has a private IP and is connected
4. **Network Security Groups**: Ensure NSGs allow PostgreSQL traffic (port 5432)

### Outputs

When using existing database with VNet peering, additional outputs are available:

- `postgres_host`: Resolves to the private endpoint FQDN
- `private_endpoint_ip`: Private IP address of the database endpoint
- `vnet_peering_status`: Information about the created peering connections
