# =============================================================================
# Eon Configuration
# =============================================================================

variable "eon_endpoint" {
  type        = string
  description = "Eon API endpoint URL (same as provider configuration)"
}

variable "eon_client_id" {
  type        = string
  description = "Eon API client ID (same as provider configuration)"
}

variable "eon_client_secret" {
  type        = string
  description = "Eon API client secret (same as provider configuration)"
  sensitive   = true
}

variable "eon_project_id" {
  type        = string
  description = "Eon project ID (same as provider configuration)"
}

# =============================================================================
# Account Type Configuration
# =============================================================================

variable "enable_source_account" {
  type        = bool
  description = "Enable provisioning of source account infrastructure (for backups)"
  default     = true
}

variable "enable_restore_account" {
  type        = bool
  description = "Enable provisioning of restore account infrastructure (for restores)"
  default     = false
}

variable "reconnect_if_existing" {
  type        = bool
  description = "If an account already exists in Eon but is disconnected, automatically reconnect it. When false, existing disconnected accounts will be left as-is."
  default     = true
}

# =============================================================================
# Azure Account Configuration
# =============================================================================

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID (GUID)"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid UUID."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID (GUID)"

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid UUID."
  }
}

variable "management_group_id" {
  type        = string
  description = "Azure management group ID. Optional - if provided, roles will be scoped to the management group instead of subscription."
  default     = ""
}

variable "management_app_id" {
  type        = string
  description = "Application ID of Eon's management app. Provided by Eon."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.management_app_id))
    error_message = "Management app ID must be a valid UUID."
  }
}

variable "backup_app_id" {
  type        = string
  description = "Application ID of the customer's backup app (for source accounts). Required when enable_source_account is true."
  default     = ""

  validation {
    condition     = var.backup_app_id == "" || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.backup_app_id))
    error_message = "Backup app ID must be a valid UUID or empty."
  }
}

variable "backup_restore_app_id" {
  type        = string
  description = "Application ID of the customer's backup/restore app (for restore accounts). Required when enable_restore_account is true."
  default     = ""

  validation {
    condition     = var.backup_restore_app_id == "" || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.backup_restore_app_id))
    error_message = "Backup restore app ID must be a valid UUID or empty."
  }
}

# =============================================================================
# Source Account Configuration
# =============================================================================

variable "source_account_name" {
  type        = string
  description = "Display name for the source account in Eon. Defaults to 'Azure-{subscription_id}'."
  default     = null
}

variable "source_resource_group_name" {
  type        = string
  description = "Optional resource group name to scope source account permissions."
  default     = null
}

variable "source_resource_group_location" {
  type        = string
  description = "Location for the Eon internal backup resource group (only created in subscription scope)"
  default     = "East US"
}

variable "source_resource_group_tags" {
  type        = map(string)
  description = "Tags to apply to the Eon internal backup resource group"
  default     = {}
}

variable "source_management_role_name" {
  type        = string
  description = "Custom name for the EonSourceManagementRole. If not provided, defaults to EonSourceManagementRole-{scope_id}"
  default     = null
}

variable "source_management_admin_role_name" {
  type        = string
  description = "Custom name for the EonSourceManagementAdminRole. If not provided, defaults to EonSourceManagementAdminRole-{scope_id}"
  default     = null
}

variable "source_backup_role_name" {
  type        = string
  description = "Custom name for the EonSourceBackupRole. If not provided, defaults to EonSourceBackupRole-{scope_id}"
  default     = null
}

# =============================================================================
# Restore Account Configuration
# =============================================================================

variable "restore_account_name" {
  type        = string
  description = "Display name for the restore account in Eon. Defaults to 'Azure-{subscription_id}'."
  default     = null
}

variable "restore_location" {
  type        = string
  description = "Azure region where restore resources will be created. Required when enable_restore_account is true."
  default     = "eastus"
}

variable "restore_resource_group_name" {
  type        = string
  description = "Optional resource group name to scope restore account permissions. If not provided, roles will be scoped to the subscription."
  default     = null
}

variable "restore_resource_group_tags" {
  type        = map(string)
  description = "Tags to apply to resources created for restore operations"
  default     = {}
}

variable "adx_service_principal_id" {
  type        = string
  description = "Optional. The object ID of the ADX cluster service principal. Only required for specialized deployment architectures."
  default     = null
}

variable "restore_backup_role_name" {
  type        = string
  description = "Custom name for the restore backup role. If not provided, will use default naming."
  default     = null
}

variable "restore_management_role_name" {
  type        = string
  description = "Custom name for the restore management role. If not provided, will use default naming."
  default     = null
}

variable "restore_operations_role_name" {
  type        = string
  description = "Custom name for the restore operations role. If not provided, will use default naming."
  default     = null
}

variable "restore_role_name" {
  type        = string
  description = "Custom name for the restore role. If not provided, will use default naming."
  default     = null
}
