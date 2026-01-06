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
# Data Sources
# -----------------------------------------------------------------------------

# Get existing source accounts from Eon
data "eon_source_accounts" "existing" {}

# Get existing restore accounts from Eon
data "eon_restore_accounts" "existing" {}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Find existing source account for this Azure subscription
  existing_source_account = [
    for acc in data.eon_source_accounts.existing.accounts :
    acc if acc.provider_account_id == var.subscription_id
  ]
  source_account_exists          = length(local.existing_source_account) > 0
  source_account_id              = local.source_account_exists ? local.existing_source_account[0].id : null
  source_account_status          = local.source_account_exists ? local.existing_source_account[0].status : null
  source_account_needs_reconnect = local.source_account_exists && local.source_account_status != null && contains(["DISCONNECTED", "INSUFFICIENT_PERMISSIONS"], local.source_account_status)

  # Find existing restore account for this Azure subscription
  existing_restore_account = [
    for acc in data.eon_restore_accounts.existing.accounts :
    acc if acc.provider_account_id == var.subscription_id
  ]
  restore_account_exists          = length(local.existing_restore_account) > 0
  restore_account_id              = local.restore_account_exists ? local.existing_restore_account[0].id : null
  restore_account_status          = local.restore_account_exists ? local.existing_restore_account[0].status : null
  restore_account_needs_reconnect = local.restore_account_exists && local.restore_account_status != null && contains(["DISCONNECTED", "INSUFFICIENT_PERMISSIONS"], local.restore_account_status)
}

# -----------------------------------------------------------------------------
# Azure Source Account Infrastructure
# -----------------------------------------------------------------------------

module "azure_source_account" {
  count  = var.enable_source_account ? 1 : 0
  source = "https://eon.blob.core.windows.net/public/onboarding/v1.1.3/terraform/source.zip"

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

# Reconnect source account if disconnected or has insufficient permissions
resource "terraform_data" "reconnect_source_account" {
  count = var.enable_source_account && var.reconnect_if_existing && local.source_account_needs_reconnect ? 1 : 0

  # Trigger reconnect when the subscription changes
  input = var.subscription_id

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      TOKEN=$(curl -sf -X POST '${var.eon_endpoint}/api/v1/token' \
        -H 'Content-Type: application/json' \
        -d '{"clientId": "${var.eon_client_id}", "clientSecret": "${var.eon_client_secret}"}' \
        | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

      curl -sf -X POST '${var.eon_endpoint}/api/v1/projects/${var.eon_project_id}/source-accounts/${local.source_account_id}/reconnect' \
        -H "Authorization: Bearer $TOKEN" \
        -H 'Content-Type: application/json' \
        -d '{"sourceAccountAttributes": {"cloudProvider": "AZURE", "azure": {"tenantId": "${var.tenant_id}", "subscriptionId": "${var.subscription_id}"}}}'

      echo "Successfully reconnected source account ${local.source_account_id}"
    EOT
  }

  depends_on = [module.azure_source_account]
}

# Create new source account only if it doesn't exist
resource "eon_source_account" "this" {
  count = var.enable_source_account && !local.source_account_exists ? 1 : 0

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

# Reconnect restore account if disconnected or has insufficient permissions
resource "terraform_data" "reconnect_restore_account" {
  count = var.enable_restore_account && var.reconnect_if_existing && local.restore_account_needs_reconnect ? 1 : 0

  # Trigger reconnect when the subscription changes
  input = var.subscription_id

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      TOKEN=$(curl -sf -X POST '${var.eon_endpoint}/api/v1/token' \
        -H 'Content-Type: application/json' \
        -d '{"clientId": "${var.eon_client_id}", "clientSecret": "${var.eon_client_secret}"}' \
        | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

      curl -sf -X POST '${var.eon_endpoint}/api/v1/projects/${var.eon_project_id}/restore-accounts/${local.restore_account_id}/reconnect' \
        -H "Authorization: Bearer $TOKEN" \
        -H 'Content-Type: application/json' \
        -d '{"restoreAccountAttributes": {"cloudProvider": "AZURE", "azure": {"tenantId": "${var.tenant_id}", "subscriptionId": "${var.subscription_id}"}}}'

      echo "Successfully reconnected restore account ${local.restore_account_id}"
    EOT
  }

  depends_on = [module.azure_restore_account]
}

# Create new restore account only if it doesn't exist
resource "eon_restore_account" "this" {
  count = var.enable_restore_account && !local.restore_account_exists ? 1 : 0

  cloud_provider = "AZURE"
  name           = var.restore_account_name != null ? var.restore_account_name : "Azure-${var.subscription_id}"

  azure {
    tenant_id           = var.tenant_id
    subscription_id     = var.subscription_id
    resource_group_name = var.restore_resource_group_name
  }

  depends_on = [module.azure_restore_account]
}
