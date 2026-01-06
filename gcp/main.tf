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
  source_account_exists          = length(local.existing_source_account) > 0
  source_account_id              = local.source_account_exists ? local.existing_source_account[0].id : null
  source_account_status          = local.source_account_exists ? local.existing_source_account[0].status : null
  source_account_needs_reconnect = local.source_account_exists && local.source_account_status != null && contains(["DISCONNECTED", "INSUFFICIENT_PERMISSIONS"], local.source_account_status)

  # Find existing restore account for this GCP project
  existing_restore_account = [
    for acc in data.eon_restore_accounts.existing.accounts :
    acc if acc.provider_account_id == var.project_id
  ]
  restore_account_exists          = length(local.existing_restore_account) > 0
  restore_account_id              = local.restore_account_exists ? local.existing_restore_account[0].id : null
  restore_account_status          = local.restore_account_exists ? local.existing_restore_account[0].status : null
  restore_account_needs_reconnect = local.restore_account_exists && local.restore_account_status != null && contains(["DISCONNECTED", "INSUFFICIENT_PERMISSIONS"], local.restore_account_status)
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
# Pre-enable Firestore API for Restore Account
# -----------------------------------------------------------------------------
# The external module enables APIs but Firestore can take time to propagate.
# Pre-enabling with a delay ensures the database creation succeeds on first try.

resource "google_project_service" "firestore_api" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "time_sleep" "wait_for_firestore_api" {
  depends_on      = [google_project_service.firestore_api]
  create_duration = "30s"
}

# -----------------------------------------------------------------------------
# GCP Restore Account Infrastructure
# -----------------------------------------------------------------------------
# Note: This module is always instantiated due to Terraform limitations.
# The Eon registration is controlled by enable_restore_account.

module "gcp_restore_setup" {
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/gcp-eon-setup.zip"

  account_type = "restore"
  # Use time_sleep id to create implicit dependency on Firestore API propagation
  project_id                    = time_sleep.wait_for_firestore_api.id != "" ? var.project_id : var.project_id
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
# Wait for IAM Propagation
# -----------------------------------------------------------------------------
# GCP IAM changes can take up to 60 seconds to propagate. This delay ensures
# that all IAM bindings (especially workload identity) are effective before
# Eon attempts to verify connectivity by impersonating the service accounts.

resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [
    module.gcp_source_setup,
    module.gcp_restore_setup,
  ]

  create_duration = "60s"

  # Only wait on initial creation, not on every apply
  triggers = {
    source_sa  = module.gcp_source_setup.service_account_emails.source_sa
    restore_sa = module.gcp_restore_setup.service_account_emails.restore_sa
  }
}

# -----------------------------------------------------------------------------
# Register Source Account with Eon
# -----------------------------------------------------------------------------

# Reconnect source account if disconnected or has insufficient permissions
resource "terraform_data" "reconnect_source_account" {
  count = var.enable_source_account && var.reconnect_if_existing && local.source_account_needs_reconnect ? 1 : 0

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

  # Wait for IAM propagation before Eon verifies connectivity
  depends_on = [time_sleep.wait_for_iam_propagation]
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

  # Wait for IAM propagation before Eon verifies connectivity
  depends_on = [time_sleep.wait_for_iam_propagation]
}

# -----------------------------------------------------------------------------
# Register Restore Account with Eon
# -----------------------------------------------------------------------------

# Reconnect restore account if disconnected or has insufficient permissions
resource "terraform_data" "reconnect_restore_account" {
  count = var.enable_restore_account && var.reconnect_if_existing && local.restore_account_needs_reconnect ? 1 : 0

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

  # Wait for IAM propagation before Eon verifies connectivity
  depends_on = [time_sleep.wait_for_iam_propagation]
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

  # Wait for IAM propagation before Eon verifies connectivity
  depends_on = [time_sleep.wait_for_iam_propagation]
}
