# =============================================================================
# Example: GCP Source and Restore Account Provisioning
# =============================================================================
#
# This example demonstrates how to use the Eon GCP module to provision
# both source and restore account infrastructure.
#
# Prerequisites:
#   1. Eon account credentials (client_id, client_secret, endpoint, project_id)
#   2. Eon account ID (UUID)
#   3. Control plane service account (provided by Eon)
#   4. Scanning project ID (provided by Eon, for source accounts)
#   5. GCP credentials configured (application default credentials or service account)
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars
#   2. Fill in your credentials
#   3. Run: terraform init && terraform apply
#
# =============================================================================

terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
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

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}

provider "eon" {
  client_id     = var.eon_client_id
  client_secret = var.eon_client_secret
  endpoint      = var.eon_endpoint
  project_id    = var.eon_project_id
}

# -----------------------------------------------------------------------------
# Eon GCP Module
# -----------------------------------------------------------------------------

module "eon_gcp" {
  source = "../../gcp"

  # Eon API configuration (same as provider)
  eon_endpoint      = var.eon_endpoint
  eon_client_id     = var.eon_client_id
  eon_client_secret = var.eon_client_secret
  eon_project_id    = var.eon_project_id
  eon_account_id    = var.eon_account_id

  # GCP project configuration
  project_id                    = var.project_id
  control_plane_service_account = var.control_plane_service_account

  # Account types to provision
  enable_source_account  = true
  enable_restore_account = true

  # Source account configuration (required for source accounts)
  scanning_project_id = var.scanning_project_id

  # Optional: Organization/folder scope (for source accounts)
  # organization_id = "123456789012"
  # folder_id       = "123456789012"

  # Optional: Shared VPC host project (for restore accounts)
  # host_project_id = "shared-vpc-host-project"

  # Optional: Custom display names in Eon
  # source_account_name  = "Production GCP"
  # restore_account_name = "Production GCP Restore"

  # Feature toggles (all default to true)
  # enable_gcs      = true
  # enable_gce      = true
  # enable_cloudsql = true
  # enable_bigquery = true

  # Optional: Enable CDC backup bucket notification management (source only)
  # enable_gcs_bucket_notification_management = true

  # Optional: Firestore location for restore command results
  # firestore_location = "nam5"

  # Optional: Customize supported restore regions
  # eon_restore_regions = ["us-central1", "us-east1", "europe-west1"]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "project_id" {
  value       = module.eon_gcp.project_id
  description = "The GCP project ID"
}

# Source account outputs
output "source_service_account_email" {
  value       = module.eon_gcp.source_service_account_email
  description = "The email of the Eon source (discovery) service account"
}

output "source_backup_service_account_email" {
  value       = module.eon_gcp.source_backup_service_account_email
  description = "The email of the Eon backup service account"
}

output "eon_source_account_id" {
  value       = module.eon_gcp.eon_source_account_id
  description = "The Eon source account ID"
}

output "eon_source_account_status" {
  value       = module.eon_gcp.eon_source_account_status
  description = "The connection status of the source account"
}

# Restore account outputs
output "restore_service_account_email" {
  value       = module.eon_gcp.restore_service_account_email
  description = "The email of the Eon restore service account"
}

output "restore_node_service_account_email" {
  value       = module.eon_gcp.restore_node_service_account_email
  description = "The email of the Eon restore node service account"
}

output "eon_restore_account_id" {
  value       = module.eon_gcp.eon_restore_account_id
  description = "The Eon restore account ID"
}

output "eon_restore_account_status" {
  value       = module.eon_gcp.eon_restore_account_status
  description = "The connection status of the restore account"
}

# Deployment scope information
output "source_deployment_scope" {
  value       = module.eon_gcp.source_deployment_scope
  description = "Information about the source account deployment scope"
}

output "restore_deployment_scope" {
  value       = module.eon_gcp.restore_deployment_scope
  description = "Information about the restore account deployment scope"
}
