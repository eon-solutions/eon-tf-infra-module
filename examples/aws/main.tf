# =============================================================================
# Example: AWS Source and Restore Account Provisioning
# =============================================================================
#
# This example demonstrates how to use the Eon AWS module to provision
# both source and restore account infrastructure.
#
# Prerequisites:
#   1. Eon account credentials (client_id, client_secret, endpoint, project_id)
#   2. Eon account UUID (eon_account_id)
#   3. Eon scanning account ID (provided by Eon)
#   4. AWS credentials configured
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
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "eon" {
  client_id     = var.eon_client_id
  client_secret = var.eon_client_secret
  endpoint      = var.eon_endpoint
  project_id    = var.eon_project_id
}

# -----------------------------------------------------------------------------
# Eon AWS Module
# -----------------------------------------------------------------------------

module "eon_aws" {
  source = "../../aws"

  providers = {
    aws = aws
    eon = eon
  }

  # Eon API configuration (same as provider)
  eon_endpoint      = var.eon_endpoint
  eon_client_id     = var.eon_client_id
  eon_client_secret = var.eon_client_secret
  eon_project_id    = var.eon_project_id

  # Required
  eon_account_id      = var.eon_account_id
  scanning_account_id = var.scanning_account_id

  # Account types to provision
  enable_source_account  = true
  enable_restore_account = true

  # Optional: Override AWS account ID (defaults to caller identity)
  # aws_account_id = "123456789012"

  # Optional: Custom display names in Eon
  # source_account_name  = "Production AWS"
  # restore_account_name = "Production AWS Restore"

  # Optional: Custom role names
  # source_role_name  = "EonSourceAccountRole"
  # restore_role_name = "EonRestoreAccountRole"

  # Source account feature toggles (all default to true except metrics)
  # enable_s3_cdc_backup                      = true
  # enable_s3_bucket_notifications_management = true
  # enable_dynamodb_streams                   = true
  # enable_eks                                = true
  # enable_temporary_volumes_method           = true
  # enable_aurora_clone                       = true
  # enable_s3_inventory_management            = true
  # source_enable_account_metrics             = false

  # Restore account feature toggles
  # restore_enable_account_metrics = false
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "aws_account_id" {
  value       = module.eon_aws.aws_account_id
  description = "The AWS account ID"
}

# Source account outputs
output "source_role_arn" {
  value       = module.eon_aws.source_role_arn
  description = "The ARN of the Eon Source Account Role"
}

output "eon_source_account_id" {
  value       = module.eon_aws.eon_source_account_id
  description = "The Eon source account ID"
}

output "eon_source_account_status" {
  value       = module.eon_aws.eon_source_account_status
  description = "The connection status of the source account"
}

# Restore account outputs
output "restore_role_arn" {
  value       = module.eon_aws.restore_role_arn
  description = "The ARN of the Eon Restore Account Role"
}

output "eon_restore_account_id" {
  value       = module.eon_aws.eon_restore_account_id
  description = "The Eon restore account ID"
}

output "eon_restore_account_status" {
  value       = module.eon_aws.eon_restore_account_status
  description = "The connection status of the restore account"
}
