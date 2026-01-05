# =============================================================================
# Azure Account Output
# =============================================================================

output "subscription_id" {
  value       = var.subscription_id
  description = "The Azure subscription ID where the roles were created"
}

output "tenant_id" {
  value       = var.tenant_id
  description = "The Azure AD tenant ID"
}

# =============================================================================
# Source Account - Eon Outputs
# =============================================================================

output "eon_source_account_id" {
  value = var.enable_source_account ? (
    local.source_account_exists ? local.source_account_id : eon_source_account.this[0].id
  ) : null
  description = "The Eon source account ID - reference this for backup policies"
}

output "eon_source_account_status" {
  value = var.enable_source_account ? (
    local.source_account_exists ? (local.source_account_disconnected ? "RECONNECTED" : local.source_account_status) : eon_source_account.this[0].status
  ) : null
  description = "The connection status of the source account in Eon"
}

# =============================================================================
# Restore Account - Eon Outputs
# =============================================================================

output "eon_restore_account_id" {
  value = var.enable_restore_account ? (
    local.restore_account_exists ? local.restore_account_id : eon_restore_account.this[0].id
  ) : null
  description = "The Eon restore account ID - reference this for restore operations"
}

output "eon_restore_account_status" {
  value = var.enable_restore_account ? (
    local.restore_account_exists ? (local.restore_account_disconnected ? "RECONNECTED" : local.restore_account_status) : eon_restore_account.this[0].status
  ) : null
  description = "The connection status of the restore account in Eon"
}

