# =============================================================================
# Eon AWS Account Provisioning Module
# =============================================================================
#
# This module provisions AWS accounts for Eon by:
# 1. Creating IAM roles and policies for Eon cross-account access
# 2. Registering the account as a source and/or restore account in Eon
#
# Usage:
#   module "eon_aws" {
#     source = "github.com/eon-solutions/eon-tf-infra-module//aws"
#
#     eon_account_id      = "your-eon-account-uuid"
#     scanning_account_id = "your-scanning-account-id"
#
#     # Enable source account (for backups)
#     enable_source_account = true
#
#     # Enable restore account (for restores)
#     enable_restore_account = true
#   }
#
# =============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Use explicitly provided AWS account ID, or fall back to caller identity
  aws_account_id = coalesce(var.aws_account_id, data.aws_caller_identity.current.account_id)
}

# -----------------------------------------------------------------------------
# AWS Source Account Infrastructure
# -----------------------------------------------------------------------------

module "aws_source_account" {
  count  = var.enable_source_account ? 1 : 0
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/eon-aws-source-account-tf.zip"

  providers = {
    aws = aws
  }

  eon_account_id      = var.eon_account_id
  scanning_account_id = var.scanning_account_id
  role_name           = var.source_role_name

  enable_s3_cdc_backup                      = var.enable_s3_cdc_backup
  enable_s3_bucket_notifications_management = var.enable_s3_bucket_notifications_management
  enable_dynamodb_streams                   = var.enable_dynamodb_streams
  enable_eks                                = var.enable_eks
  enable_account_metrics                    = var.source_enable_account_metrics
  enable_temporary_volumes_method           = var.enable_temporary_volumes_method
  enable_aurora_clone                       = var.enable_aurora_clone
  enable_s3_inventory_management            = var.enable_s3_inventory_management

  permissions_boundary_name = var.permissions_boundary_name != null ? var.permissions_boundary_name : ""
}

# -----------------------------------------------------------------------------
# AWS Restore Account Infrastructure
# -----------------------------------------------------------------------------

module "aws_restore_account" {
  count  = var.enable_restore_account ? 1 : 0
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/eon-aws-restore-account-tf.zip"

  providers = {
    aws = aws
  }

  eon_account_id         = var.eon_account_id
  role_name              = var.restore_role_name
  enable_account_metrics = var.restore_enable_account_metrics

  permissions_boundary_name = var.permissions_boundary_name != null ? var.permissions_boundary_name : ""
}

# -----------------------------------------------------------------------------
# IAM Propagation Delay
# -----------------------------------------------------------------------------

# Wait for IAM roles/policies to propagate before Eon tries to assume them
resource "time_sleep" "wait_for_source_iam" {
  count = var.enable_source_account ? 1 : 0

  depends_on      = [module.aws_source_account]
  create_duration = "15s"
}

resource "time_sleep" "wait_for_restore_iam" {
  count = var.enable_restore_account ? 1 : 0

  depends_on      = [module.aws_restore_account]
  create_duration = "15s"
}

# -----------------------------------------------------------------------------
# Register Source Account with Eon
# -----------------------------------------------------------------------------

# Register the source account with Eon. Re-applying is idempotent: an existing
# matching account is adopted into state, and a disconnected account is
# reconnected in place.
resource "eon_source_account" "this" {
  count = var.enable_source_account ? 1 : 0

  cloud_provider = "AWS"
  name           = var.source_account_name != null ? var.source_account_name : "AWS-${local.aws_account_id}"

  aws {
    role_arn = module.aws_source_account[0].eon_source_account_role_arn
  }

  depends_on = [time_sleep.wait_for_source_iam]
}

# -----------------------------------------------------------------------------
# Register Restore Account with Eon
# -----------------------------------------------------------------------------

# Register the restore account with Eon. Re-applying is idempotent: an existing
# matching account is adopted into state. To change attributes of an existing
# restore account, taint it so it is recreated.
resource "eon_restore_account" "this" {
  count = var.enable_restore_account ? 1 : 0

  cloud_provider = "AWS"
  name           = var.restore_account_name != null ? var.restore_account_name : "AWS-${local.aws_account_id}"

  aws {
    role_arn = module.aws_restore_account[0].eon_restore_account_role_arn
  }

  depends_on = [time_sleep.wait_for_restore_iam]
}
