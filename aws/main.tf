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

# Get existing source accounts from Eon
data "eon_source_accounts" "existing" {}

# Get existing restore accounts from Eon
data "eon_restore_accounts" "existing" {}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Use explicitly provided AWS account ID, or fall back to caller identity
  aws_account_id = coalesce(var.aws_account_id, data.aws_caller_identity.current.account_id)

  # Find existing source account for this AWS account
  existing_source_account = [
    for acc in coalesce(data.eon_source_accounts.existing.accounts, []) :
    acc if acc.provider_account_id == local.aws_account_id
  ]
  source_account_exists          = length(local.existing_source_account) > 0
  source_account_id              = local.source_account_exists ? local.existing_source_account[0].id : null
  source_account_status          = local.source_account_exists ? local.existing_source_account[0].status : null
  source_account_needs_reconnect = local.source_account_exists && contains(["DISCONNECTED", "INSUFFICIENT_PERMISSIONS"], coalesce(local.source_account_status, ""))

  # Find existing restore account for this AWS account
  existing_restore_account = [
    for acc in coalesce(data.eon_restore_accounts.existing.accounts, []) :
    acc if acc.provider_account_id == local.aws_account_id
  ]
  restore_account_exists          = length(local.existing_restore_account) > 0
  restore_account_id              = local.restore_account_exists ? local.existing_restore_account[0].id : null
  restore_account_status          = local.restore_account_exists ? local.existing_restore_account[0].status : null
  restore_account_needs_reconnect = local.restore_account_exists && contains(["DISCONNECTED", "INSUFFICIENT_PERMISSIONS"], coalesce(local.restore_account_status, ""))
}

# -----------------------------------------------------------------------------
# AWS Source Account Infrastructure
# -----------------------------------------------------------------------------

module "aws_source_account" {
  count  = var.enable_source_account ? 1 : 0
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/eon-aws-source-account-tf.zip"

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
}

# -----------------------------------------------------------------------------
# AWS Restore Account Infrastructure
# -----------------------------------------------------------------------------

module "aws_restore_account" {
  count  = var.enable_restore_account ? 1 : 0
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/eon-aws-restore-account-tf.zip"

  eon_account_id         = var.eon_account_id
  role_name              = var.restore_role_name
  enable_account_metrics = var.restore_enable_account_metrics
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

# Reconnect source account if disconnected or has insufficient permissions
resource "terraform_data" "reconnect_source_account" {
  count = var.enable_source_account && var.reconnect_if_existing && local.source_account_needs_reconnect ? 1 : 0

  # Trigger reconnect when the role ARN changes
  input = module.aws_source_account[0].eon_source_account_role_arn

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
        -d '{"sourceAccountAttributes": {"cloudProvider": "AWS", "aws": {"roleArn": "${module.aws_source_account[0].eon_source_account_role_arn}"}}}'

      echo "Successfully reconnected source account ${local.source_account_id}"
    EOT
  }

  depends_on = [time_sleep.wait_for_source_iam]
}

# Create new source account only if it doesn't exist
resource "eon_source_account" "this" {
  count = var.enable_source_account && !local.source_account_exists ? 1 : 0

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

# Reconnect restore account if disconnected or has insufficient permissions
resource "terraform_data" "reconnect_restore_account" {
  count = var.enable_restore_account && var.reconnect_if_existing && local.restore_account_needs_reconnect ? 1 : 0

  # Trigger reconnect when the role ARN changes
  input = module.aws_restore_account[0].eon_restore_account_role_arn

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
        -d '{"restoreAccountAttributes": {"cloudProvider": "AWS", "aws": {"roleArn": "${module.aws_restore_account[0].eon_restore_account_role_arn}"}}}'

      echo "Successfully reconnected restore account ${local.restore_account_id}"
    EOT
  }

  depends_on = [time_sleep.wait_for_restore_iam]
}

# Create new restore account only if it doesn't exist
resource "eon_restore_account" "this" {
  count = var.enable_restore_account && !local.restore_account_exists ? 1 : 0

  cloud_provider = "AWS"
  name           = var.restore_account_name != null ? var.restore_account_name : "AWS-${local.aws_account_id}"

  aws {
    role_arn = module.aws_restore_account[0].eon_restore_account_role_arn
  }

  depends_on = [time_sleep.wait_for_restore_iam]
}
