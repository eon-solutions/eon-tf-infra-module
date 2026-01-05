# =============================================================================
# Eon Configuration
# =============================================================================

variable "eon_account_id" {
  type        = string
  description = "Eon account UUID. Used as external ID for AWS trust policy."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.eon_account_id))
    error_message = "Eon account ID must be a valid UUID."
  }
}

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
# AWS Account Configuration
# =============================================================================

# By default, the module uses the AWS caller identity to determine the account ID.
# To explicitly specify an AWS account ID instead of using the caller identity,
# set the aws_account_id variable:
#
#   aws_account_id = "123456789012"
#
# This is useful when:
# - Running Terraform with cross-account assume role credentials
# - The caller identity differs from the target account
# - You want to ensure a specific account ID is used regardless of credentials

variable "aws_account_id" {
  type        = string
  description = "AWS account ID. If not provided, uses the caller identity."
  default     = null

  validation {
    condition     = var.aws_account_id == null || can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS account ID must be a 12-digit number."
  }
}

# =============================================================================
# AWS Source Account Configuration
# =============================================================================

variable "scanning_account_id" {
  type        = string
  description = "Eon scanning AWS account ID. Provided by Eon. Required when enable_source_account is true."
  default     = ""

  validation {
    condition     = var.scanning_account_id == "" || can(regex("^[0-9]{12}$", var.scanning_account_id))
    error_message = "Scanning account ID must be a 12-digit number or empty."
  }
}

variable "source_account_name" {
  type        = string
  description = "Display name for the source account in Eon. Defaults to 'AWS-{account_id}'."
  default     = null
}

variable "source_role_name" {
  type        = string
  description = "Name of the IAM role to create for source account"
  default     = "EonSourceAccountRole"
}

# =============================================================================
# AWS Restore Account Configuration
# =============================================================================

variable "restore_account_name" {
  type        = string
  description = "Display name for the restore account in Eon. Defaults to 'AWS-{account_id}'."
  default     = null
}

variable "restore_role_name" {
  type        = string
  description = "Name of the IAM role to create for restore account"
  default     = "EonRestoreAccountRole"
}

# =============================================================================
# Source Account Feature Toggles
# =============================================================================

variable "enable_s3_cdc_backup" {
  type        = bool
  description = "Allow Eon to manage event-based S3 backup resources (EventBridge rules)"
  default     = true
}

variable "enable_s3_bucket_notifications_management" {
  type        = bool
  description = "Allow Eon to modify S3 bucket notifications"
  default     = true
}

variable "enable_dynamodb_streams" {
  type        = bool
  description = "Allow Eon to enable DynamoDB streams for point-in-time recovery"
  default     = true
}

variable "enable_eks" {
  type        = bool
  description = "Allow Eon to access and backup EKS cluster resources"
  default     = true
}

variable "source_enable_account_metrics" {
  type        = bool
  description = "Allow Eon to send backup metrics to CloudWatch in your source account"
  default     = false
}

variable "enable_temporary_volumes_method" {
  type        = bool
  description = "Allow Eon to create temporary EBS volumes for scanning operations"
  default     = true
}

variable "enable_aurora_clone" {
  type        = bool
  description = "Allow Eon to clone Aurora clusters for scanning operations"
  default     = true
}

variable "enable_s3_inventory_management" {
  type        = bool
  description = "Allow Eon to manage S3 inventory configurations for large bucket discovery"
  default     = true
}

# =============================================================================
# Restore Account Feature Toggles
# =============================================================================

variable "restore_enable_account_metrics" {
  type        = bool
  description = "Allow Eon to send restore metrics to CloudWatch in your restore account"
  default     = false
}
