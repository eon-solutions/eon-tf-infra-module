# =============================================================================
# Eon Azure Account Provisioning Module
# =============================================================================
#
# This module provisions Azure subscriptions for Eon by:
# 1. Creating custom Azure roles and role assignments for Eon access
# 2. Registering the subscription as a source and/or restore account in Eon
#
# Prerequisites:
#   - Azure App Registration with Eon's management and backup apps configured
#   - Azure AD service principals created for the apps in the target tenant
#
# Usage:
#   module "eon_azure" {
#     source = "github.com/eon-solutions/eon-tf-infra-module//azure"
#
#     subscription_id   = "your-azure-subscription-id"
#     management_app_id = "eon-management-app-id"
#     backup_app_id     = "eon-backup-app-id"
#
#     # Enable source account (for backups)
#     enable_source_account = true
#
#     # Enable restore account (for restores)
#     enable_restore_account  = true
#     backup_restore_app_id   = "eon-backup-restore-app-id"
#     restore_location        = "eastus"
#   }
#
# =============================================================================

# -----------------------------------------------------------------------------
# Azure Source Account Infrastructure
# -----------------------------------------------------------------------------

module "azure_source_account" {
  count  = var.enable_source_account ? 1 : 0
  source = "https://eon.blob.core.windows.net/public/onboarding/v1.1.3/terraform/source.zip"

  providers = {
    azurerm = azurerm
    azuread = azuread
  }

  subscription_id     = var.subscription_id
  management_group_id = var.management_group_id
  management_app_id   = var.management_app_id
  backup_app_id       = var.backup_app_id

  eon_backup_rg_location     = var.source_resource_group_location
  eon_backup_rg_tags         = var.source_resource_group_tags
  management_role_name       = var.source_management_role_name
  management_admin_role_name = var.source_management_admin_role_name
  backup_role_name           = var.source_backup_role_name
}

# -----------------------------------------------------------------------------
# Azure Restore Account Infrastructure
# -----------------------------------------------------------------------------

module "azure_restore_account" {
  count  = var.enable_restore_account ? 1 : 0
  source = "https://eon.blob.core.windows.net/public/onboarding/v1.1.3/terraform/restore.zip"

  providers = {
    azurerm = azurerm
    azuread = azuread
  }

  project_id            = var.eon_project_id
  subscription_id       = var.subscription_id
  management_app_id     = var.management_app_id
  backup_restore_app_id = var.backup_restore_app_id
  location              = var.restore_location

  resource_group_name          = var.restore_resource_group_name
  tags                         = var.restore_resource_group_tags
  adx_service_principal_id     = var.adx_service_principal_id
  restore_backup_role_name     = var.restore_backup_role_name
  restore_management_role_name = var.restore_management_role_name
  restore_operations_role_name = var.restore_operations_role_name
  restore_role_name            = var.restore_role_name
}

# -----------------------------------------------------------------------------
# Register Source Account with Eon
# -----------------------------------------------------------------------------

# Register the source account with Eon. Re-applying is idempotent: an existing
# matching account is adopted into state, and a disconnected account is
# reconnected in place.
resource "eon_source_account" "this" {
  count = var.enable_source_account ? 1 : 0

  cloud_provider = "AZURE"
  name           = var.source_account_name != null ? var.source_account_name : "Azure-${var.subscription_id}"

  azure {
    tenant_id           = var.tenant_id
    subscription_id     = var.subscription_id
    resource_group_name = var.source_resource_group_name
  }

  depends_on = [module.azure_source_account]
}

# -----------------------------------------------------------------------------
# Register Restore Account with Eon
# -----------------------------------------------------------------------------

# Register the restore account with Eon. Re-applying is idempotent: an existing
# matching account is adopted into state. To change attributes of an existing
# restore account, taint it so it is recreated.
resource "eon_restore_account" "this" {
  count = var.enable_restore_account ? 1 : 0

  cloud_provider = "AZURE"
  name           = var.restore_account_name != null ? var.restore_account_name : "Azure-${var.subscription_id}"

  azure {
    tenant_id           = var.tenant_id
    subscription_id     = var.subscription_id
    resource_group_name = var.restore_resource_group_name
  }

  depends_on = [module.azure_restore_account]
}
