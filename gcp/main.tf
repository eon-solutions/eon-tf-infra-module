# =============================================================================
# Eon GCP Account Provisioning Module
# =============================================================================
#
# This module provisions GCP projects for Eon by:
# 1. Creating service accounts and custom IAM roles for Eon access
# 2. Registering the project as a source and/or restore account in Eon
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
# GCP Source Account Infrastructure
# -----------------------------------------------------------------------------

module "gcp_source_setup" {
  count  = var.enable_source_account ? 1 : 0
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/gcp-eon-setup.zip"

  providers = {
    google = google
  }

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

module "gcp_restore_setup" {
  count  = var.enable_restore_account ? 1 : 0
  source = "https://eon-public-b2b628cc-1d96-4fda-8dae-c3b1ad3ea03b.s3.amazonaws.com/gcp-eon-setup.zip"

  providers = {
    google = google
  }

  account_type                  = "restore"
  project_id                    = var.project_id
  eon_account_id                = var.eon_account_id
  control_plane_service_account = var.control_plane_service_account

  # Restore-specific options
  host_project_id    = var.host_project_id
  firestore_location = var.firestore_location

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

resource "time_sleep" "wait_for_source_iam_propagation" {
  count      = var.enable_source_account ? 1 : 0
  depends_on = [module.gcp_source_setup]

  create_duration = "60s"

  triggers = {
    source_sa = module.gcp_source_setup[0].service_account_emails.source_sa
  }
}

resource "time_sleep" "wait_for_restore_iam_propagation" {
  count      = var.enable_restore_account ? 1 : 0
  depends_on = [module.gcp_restore_setup]

  create_duration = "60s"

  triggers = {
    restore_sa = module.gcp_restore_setup[0].service_account_emails.restore_sa
  }
}

# -----------------------------------------------------------------------------
# Register Source Account with Eon
# -----------------------------------------------------------------------------

# Register the source account with Eon. Re-applying is idempotent: an existing
# matching account is adopted into state, and a disconnected account is
# reconnected in place.
resource "eon_source_account" "this" {
  count = var.enable_source_account ? 1 : 0

  cloud_provider = "GCP"
  name           = var.source_account_name != null ? var.source_account_name : "GCP-${var.project_id}"

  gcp {
    project_id      = var.project_id
    service_account = module.gcp_source_setup[0].service_account_emails.source_sa
  }

  depends_on = [time_sleep.wait_for_source_iam_propagation]
}

# -----------------------------------------------------------------------------
# Register Restore Account with Eon
# -----------------------------------------------------------------------------

# Register the restore account with Eon. Re-applying is idempotent: an existing
# matching account is adopted into state. To change attributes of an existing
# restore account, taint it so it is recreated.
resource "eon_restore_account" "this" {
  count = var.enable_restore_account ? 1 : 0

  cloud_provider = "GCP"
  name           = var.restore_account_name != null ? var.restore_account_name : "GCP-${var.project_id}"

  gcp {
    project_id      = var.project_id
    service_account = module.gcp_restore_setup[0].service_account_emails.restore_sa
  }

  depends_on = [time_sleep.wait_for_restore_iam_propagation]
}
