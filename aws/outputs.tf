# =============================================================================
# AWS Account Output
# =============================================================================

output "aws_account_id" {
  value       = local.aws_account_id
  description = "The AWS account ID where the roles were created"
}

# =============================================================================
# Source Account - AWS Outputs
# =============================================================================

output "source_role_arn" {
  value       = var.enable_source_account ? module.aws_source_account[0].eon_source_account_role_arn : null
  description = "The ARN of the Eon Source Account Role"
}

output "source_role_name" {
  value       = var.enable_source_account ? module.aws_source_account[0].eon_source_account_role_name : null
  description = "The name of the Eon Source Account Role"
}

output "source_backup_access_role_arn" {
  value       = var.enable_source_account ? module.aws_source_account[0].eon_source_account_backup_access_role_arn : null
  description = "The ARN of the Eon Source Account Backup Access Role"
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
# Restore Account - AWS Outputs
# =============================================================================

output "restore_role_arn" {
  value       = var.enable_restore_account ? module.aws_restore_account[0].eon_restore_account_role_arn : null
  description = "The ARN of the Eon Restore Account Role"
}

output "restore_role_name" {
  value       = var.enable_restore_account ? module.aws_restore_account[0].eon_restore_account_role_name : null
  description = "The name of the Eon Restore Account Role"
}

output "restore_node_role_arn" {
  value       = var.enable_restore_account ? module.aws_restore_account[0].eon_restore_node_role_arn : null
  description = "The ARN of the Eon Restore Node Role"
}

output "restore_node_instance_profile_arn" {
  value       = var.enable_restore_account ? module.aws_restore_account[0].eon_restore_node_instance_profile_arn : null
  description = "The ARN of the Eon Restore Node Instance Profile"
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
