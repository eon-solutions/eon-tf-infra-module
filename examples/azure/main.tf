# =============================================================================
# Example: Azure Source and Restore Account Provisioning
# =============================================================================
#
# This example demonstrates how to use the Eon Azure module to provision
# both source and restore account infrastructure.
#
# Prerequisites:
#   1. Eon account credentials (client_id, client_secret, endpoint, project_id)
#   2. Azure App Registration with Eon's management and backup apps configured
#   3. Azure AD service principals created for the apps in the target tenant
#   4. Azure CLI authenticated with appropriate permissions
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars
#   2. Fill in your credentials
#   3. Run: terraform init && terraform apply
#
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.83, < 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    eon = {
      source  = "eon-io/eon"
      version = "~> 2.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

provider "eon" {
  client_id     = var.eon_client_id
  client_secret = var.eon_client_secret
  endpoint      = var.eon_endpoint
  project_id    = var.eon_project_id
}

# -----------------------------------------------------------------------------
# Eon Azure Module
# -----------------------------------------------------------------------------

module "eon_azure" {
  source = "../../azure"

  # Eon API configuration (same as provider)
  eon_endpoint      = var.eon_endpoint
  eon_client_id     = var.eon_client_id
  eon_client_secret = var.eon_client_secret
  eon_project_id    = var.eon_project_id

  # Azure account configuration
  tenant_id         = var.tenant_id
  subscription_id   = var.subscription_id
  management_app_id = var.management_app_id

  # Account types to provision
  enable_source_account  = true
  enable_restore_account = true

  # Source account configuration
  backup_app_id                  = var.backup_app_id
  source_resource_group_location = var.source_resource_group_location

  # Restore account configuration
  backup_restore_app_id = var.backup_restore_app_id
  restore_location      = var.restore_location

  # Optional: Management group scope (for organization-level source accounts)
  # management_group_id = "your-management-group-id"

  # Optional: Custom display names in Eon
  # source_account_name  = "Production Azure"
  # restore_account_name = "Production Azure Restore"

  # Optional: Scope to a specific resource group
  # source_resource_group_name  = "my-source-resource-group"
  # restore_resource_group_name = "my-restore-resource-group"

  # Optional: Custom role names
  # source_management_role_name       = "EonSourceManagementRole"
  # source_management_admin_role_name = "EonSourceManagementAdminRole"
  # source_backup_role_name           = "EonSourceBackupRole"
  # restore_backup_role_name          = "EonRestoreBackupRole"
  # restore_management_role_name      = "EonRestoreManagementRole"
  # restore_operations_role_name      = "EonRestoreOperationsRole"
  # restore_role_name                 = "EonRestoreRole"

  # Optional: Tags for resources
  # source_resource_group_tags  = { Environment = "Production" }
  # restore_resource_group_tags = { Environment = "Production" }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "subscription_id" {
  value       = module.eon_azure.subscription_id
  description = "The Azure subscription ID"
}

output "tenant_id" {
  value       = module.eon_azure.tenant_id
  description = "The Azure AD tenant ID"
}

# Source account outputs
output "eon_source_account_id" {
  value       = module.eon_azure.eon_source_account_id
  description = "The Eon source account ID"
}

output "eon_source_account_status" {
  value       = module.eon_azure.eon_source_account_status
  description = "The connection status of the source account"
}

# Restore account outputs
output "eon_restore_account_id" {
  value       = module.eon_azure.eon_restore_account_id
  description = "The Eon restore account ID"
}

output "eon_restore_account_status" {
  value       = module.eon_azure.eon_restore_account_status
  description = "The connection status of the restore account"
}

