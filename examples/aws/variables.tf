# =============================================================================
# AWS Configuration
# =============================================================================

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile to use"
  default     = null
}

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
# Eon Account Configuration
# =============================================================================

variable "eon_account_id" {
  type        = string
  description = "Eon account UUID (used as external ID for AWS trust policy)"
}

variable "scanning_account_id" {
  type        = string
  description = "Eon scanning AWS account ID (provided by Eon)"
}
