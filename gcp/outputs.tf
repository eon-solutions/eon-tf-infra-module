# =============================================================================
# GCP Project Output
# =============================================================================

output "project_id" {
  value       = var.project_id
  description = "The GCP project ID where the service accounts were created"
}

# =============================================================================
# Source Account - GCP Outputs
# =============================================================================

output "source_service_account_email" {
  value       = var.enable_source_account ? module.gcp_source_setup[0].service_account_emails.source_sa : null
  description = "The email of the Eon source (discovery) service account"
}

output "source_backup_service_account_email" {
  value       = var.enable_source_account ? module.gcp_source_setup[0].service_account_emails.backup_sa : null
  description = "The email of the Eon backup service account"
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
    local.source_account_exists ? local.source_account_status : eon_source_account.this[0].status
  ) : null
  description = "The connection status of the source account in Eon. Note: after reconnection, run 'terraform apply' again to see updated status."
}

# =============================================================================
# Restore Account - GCP Outputs
# =============================================================================

output "restore_service_account_email" {
  value       = var.enable_restore_account ? module.gcp_restore_setup[0].service_account_emails.restore_sa : null
  description = "The email of the Eon restore service account"
}

output "restore_node_service_account_email" {
  value       = var.enable_restore_account ? module.gcp_restore_setup[0].service_account_emails.restore_node_sa : null
  description = "The email of the Eon restore node service account"
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
    local.restore_account_exists ? local.restore_account_status : eon_restore_account.this[0].status
  ) : null
  description = "The connection status of the restore account in Eon. Note: after reconnection, run 'terraform apply' again to see updated status."
}

# =============================================================================
# Deployment Scope Information
# =============================================================================

output "source_deployment_scope" {
  value       = var.enable_source_account ? module.gcp_source_setup[0].deployment_scope : null
  description = "Information about the source account deployment scope and configuration"
}

output "restore_deployment_scope" {
  value       = var.enable_restore_account ? module.gcp_restore_setup[0].deployment_scope : null
  description = "Information about the restore account deployment scope and configuration"
}
