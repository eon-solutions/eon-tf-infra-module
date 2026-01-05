# Azure Example

This example demonstrates how to use the Eon Azure module to provision source and restore account infrastructure.

## Prerequisites

1. Azure CLI authenticated (`az login`)
2. Eon account credentials (obtain from Eon console)
3. Azure App Registration with Eon's management and backup apps configured
4. Azure AD service principals created for the apps in the target tenant
5. Terraform >= 1.0

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your credentials:
   - Eon API credentials (client_id, client_secret, endpoint, project_id)
   - Azure tenant ID and subscription ID
   - Eon app IDs (management_app_id, backup_app_id, backup_restore_app_id)

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## What This Creates

### Source Account (for backups)
- `EonSourceManagementRole` - Custom role for resource discovery and management
- `EonSourceBackupRole` - Custom role for backup data access
- `eon-source-internal-rg` - Resource group for Eon internal resources
- Role assignments for Eon service principals
- Registers the account as a source account in Eon

### Restore Account (for restores)
- `EonRestoreManagementRole` - Custom role for restore infrastructure management
- `EonRestoreBackupRole` - Custom role for restore data access
- `EonRestoreOperationsRole` - Custom role for storage operations
- `EonRestoreRole` - Custom role for VM and disk operations
- Resource group for Eon restore operations
- Role assignments for Eon service principals
- Registers the account as a restore account in Eon

## Customization

To provision only a source account:
```hcl
enable_source_account  = true
enable_restore_account = false
```

To provision only a restore account:
```hcl
enable_source_account  = false
enable_restore_account = true
```

To scope to a management group (organization-level):
```hcl
management_group_id = "your-management-group-id"
```

To disable automatic reconnection of existing disconnected accounts:
```hcl
reconnect_if_existing = false
```

## Automatic Reconnection

If an account was previously registered with Eon but is now disconnected (e.g., after running `terraform destroy` on the Azure infrastructure), running `terraform apply` will:

1. Detect the existing disconnected account in Eon
2. Recreate the Azure infrastructure (roles, permissions, etc.)
3. Automatically reconnect the account via the Eon API

This behavior is enabled by default and can be disabled with `reconnect_if_existing = false`.
