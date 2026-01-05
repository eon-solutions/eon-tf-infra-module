# =============================================================================
# Eon Provider Configuration
# =============================================================================

variable "eon_client_id" {
  type        = string
  description = "Eon API client ID"
}

variable "eon_client_secret" {
  type        = string
  description = "Eon API client secret"
  sensitive   = true
}

variable "eon_endpoint" {
  type        = string
  description = "Eon API endpoint URL"
}

variable "eon_project_id" {
  type        = string
  description = "Eon project ID"
}

# =============================================================================
# Azure Account Configuration
# =============================================================================

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID (GUID)"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID (GUID)"
}

variable "management_app_id" {
  type        = string
  description = "Application ID of Eon's management app. Provided by Eon."
}

variable "backup_app_id" {
  type        = string
  description = "Application ID of the customer's backup app (for source accounts)"
}

variable "backup_restore_app_id" {
  type        = string
  description = "Application ID of the customer's backup/restore app (for restore accounts)"
}

# =============================================================================
# Source Account Configuration
# =============================================================================

variable "source_resource_group_location" {
  type        = string
  description = "Location for the Eon internal backup resource group"
  default     = "East US"
}

# =============================================================================
# Restore Account Configuration
# =============================================================================

variable "restore_location" {
  type        = string
  description = "Azure region where restore resources will be created"
  default     = "eastus"
}
