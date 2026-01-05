# =============================================================================
# Eon GCP Account Provisioning Module
# =============================================================================
#
# This module provisions GCP projects for Eon by:
# 1. Creating service accounts and custom IAM roles for Eon access
# 2. Registering the project as a source and/or restore account in Eon
#
# Note: Due to Terraform limitations with the external GCP setup module,
# GCP infrastructure is created for both source and restore accounts.
# Only the enabled account types are registered with Eon.
#
# Prerequisites:
#   - GCP project with appropriate APIs enabled
#   - Eon account ID and control plane service account information
#
# Usage:
#   module "eon_gcp" {
#     source = "github.com/eon-solutions/eon-tf-infra-module//gcp"
#
#     project_id                    = "your-gcp-project-id"
#     eon_account_id                = "your-eon-account-uuid"
#     control_plane_service_account = "eon-control-plane@eon-project.iam.gserviceaccount.com"
#
#     # For source accounts
#     enable_source_account = true
#     scanning_project_id   = "eon-scanning-project-id"
#
#     # For restore accounts
#     enable_restore_account = true
#   }
#
# =============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# Get existing source accounts from Eon
data "eon_source_accounts" "existing" {}

# Get existing restore accounts from Eon
data "eon_restore_accounts" "existing" {}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  # Find existing source account for this GCP project
  existing_source_account = [
    for acc in data.eon_source_accounts.existing.accounts :
    acc if acc.provider_account_id == var.project_id
  ]
  source_account_exists       = length(local.existing_source_account) > 0
  source_account_id           = local.source_account_exists ? local.existing_source_account[0].id : null
  source_account_status       = local.source_account_exists ? local.existing_source_account[0].status : null
  source_account_disconnected = local.source_account_exists && local.source_account_status == "DISCONNECTED"

  # Find existing restore account for this GCP project
  existing_restore_account = [
    for acc in data.eon_restore_accounts.existing.accounts :
    acc if acc.provider_account_id == var.project_id
  ]
  restore_account_exists       = length(local.existing_restore_account) > 0
  restore_account_id           = local.restore_account_exists ? local.existing_restore_account[0].id : null
  restore_account_status       = local.restore_account_exists ? local.existing_restore_account[0].status : null
  restore_account_disconnected = local.restore_account_exists && local.restore_account_status == "DISCONNECTED"
}

# -----------------------------------------------------------------------------
# GCP Source Account Infrastructure
# -----------------------------------------------------------------------------
# Note: This module is always instantiated due to Terraform limitations.
# The Eon registration is controlled by enable_source_account.

module "gcp_source_setup" {
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/gcp-eon-setup.zip"

  account_type                  = "source"
  project_id                    = var.project_id
  eon_account_id                = var.eon_account_id
  control_plane_service_account = var.control_plane_service_account
  scanning_project_id           = var.scanning_project_id

  # Optional organization/folder scope
  organization_id = var.organization_id
  folder_id       = var.folder_id

  # Feature toggles
  enable_gcs                                = var.enable_gcs
  enable_gcs_bucket_notification_management = var.enable_gcs_bucket_notification_management
  enable_gce                                = var.enable_gce
  enable_cloudsql                           = var.enable_cloudsql
  enable_bigquery                           = var.enable_bigquery
}

# -----------------------------------------------------------------------------
# GCP Restore Account Infrastructure
# -----------------------------------------------------------------------------
# Note: This module is always instantiated due to Terraform limitations.
# The Eon registration is controlled by enable_restore_account.

module "gcp_restore_setup" {
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/gcp-eon-setup.zip"

  account_type                  = "restore"
  project_id                    = var.project_id
  eon_account_id                = var.eon_account_id
  control_plane_service_account = var.control_plane_service_account

  # Restore-specific options
  host_project_id     = var.host_project_id
  firestore_location  = var.firestore_location
  eon_restore_regions = var.eon_restore_regions

  # Feature toggles
  enable_gcs      = var.enable_gcs
  enable_gce      = var.enable_gce
  enable_cloudsql = var.enable_cloudsql
  enable_bigquery = var.enable_bigquery
}

# -----------------------------------------------------------------------------
# Register Source Account with Eon
# -----------------------------------------------------------------------------

# Reconnect disconnected source account via API
resource "terraform_data" "reconnect_source_account" {
  count = var.enable_source_account && var.reconnect_if_existing && local.source_account_disconnected ? 1 : 0

  input = module.gcp_source_setup.service_account_emails.source_sa

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
        -d '{"sourceAccountAttributes": {"cloudProvider": "GCP", "gcp": {"serviceAccount": "${module.gcp_source_setup.service_account_emails.source_sa}"}}}'

      echo "Successfully reconnected source account ${local.source_account_id}"
    EOT
  }
}

# Create new source account only if enabled and doesn't exist
resource "eon_source_account" "this" {
  count = var.enable_source_account && !local.source_account_exists ? 1 : 0

  cloud_provider = "GCP"
  name           = var.source_account_name != null ? var.source_account_name : "GCP-${var.project_id}"

  gcp {
    project_id      = var.project_id
    service_account = module.gcp_source_setup.service_account_emails.source_sa
  }
}

# -----------------------------------------------------------------------------
# Register Restore Account with Eon
# -----------------------------------------------------------------------------

# Reconnect disconnected restore account via API
resource "terraform_data" "reconnect_restore_account" {
  count = var.enable_restore_account && var.reconnect_if_existing && local.restore_account_disconnected ? 1 : 0

  input = module.gcp_restore_setup.service_account_emails.restore_sa

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
        -d '{"restoreAccountAttributes": {"cloudProvider": "GCP", "gcp": {"serviceAccount": "${module.gcp_restore_setup.service_account_emails.restore_sa}"}}}'

      echo "Successfully reconnected restore account ${local.restore_account_id}"
    EOT
  }
}

# Create new restore account only if enabled and doesn't exist
resource "eon_restore_account" "this" {
  count = var.enable_restore_account && !local.restore_account_exists ? 1 : 0

  cloud_provider = "GCP"
  name           = var.restore_account_name != null ? var.restore_account_name : "GCP-${var.project_id}"

  gcp {
    project_id      = var.project_id
    service_account = module.gcp_restore_setup.service_account_emails.restore_sa
  }
}
