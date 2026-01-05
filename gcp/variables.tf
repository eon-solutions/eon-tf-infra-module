# =============================================================================
# Eon Configuration
# =============================================================================

variable "eon_account_id" {
  type        = string
  description = "Eon account UUID. Used for confused-deputy protection and name prefixes."

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
  description = "Enable registration of source account with Eon (for backups)"
  default     = true
}

variable "enable_restore_account" {
  type        = bool
  description = "Enable registration of restore account with Eon (for restores)"
  default     = false
}

variable "reconnect_if_existing" {
  type        = bool
  description = "If an account already exists in Eon but is disconnected, automatically reconnect it. When false, existing disconnected accounts will be left as-is."
  default     = true
}

# =============================================================================
# GCP Project Configuration
# =============================================================================

variable "project_id" {
  type        = string
  description = "The GCP project ID that will own the service accounts and custom IAM roles."

  validation {
    condition     = can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be a valid GCP project ID (6-30 characters, lowercase letters, numbers, and hyphens)."
  }
}

variable "control_plane_service_account" {
  type        = string
  description = "The GCP Workload Identity service account email that will impersonate the Eon service account. Provided by Eon."

  validation {
    condition     = can(regex("^[a-z0-9\\-]+@[a-z0-9\\-]+\\.iam\\.gserviceaccount\\.com$", var.control_plane_service_account))
    error_message = "Control plane service account must be a valid service account email."
  }
}

# =============================================================================
# Source Account Configuration
# =============================================================================

variable "scanning_project_id" {
  type        = string
  description = "GCP project that contains the eon-scan-* service account. Required for source accounts. Provided by Eon."
  default     = ""

  validation {
    condition     = var.scanning_project_id == "" || can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", var.scanning_project_id))
    error_message = "Scanning project ID must be empty or a valid GCP project ID."
  }
}

variable "source_account_name" {
  type        = string
  description = "Display name for the source account in Eon. Defaults to 'GCP-{project_id}'."
  default     = null
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID for organization-level deployments (source accounts only). When provided, custom roles will be created at the organization level."
  default     = ""

  validation {
    condition     = var.organization_id == "" || can(regex("^[0-9]{10,20}$", var.organization_id))
    error_message = "Organization ID must be empty or a valid numeric organization ID (10-20 digits)."
  }
}

variable "folder_id" {
  type        = string
  description = "GCP folder ID for folder-level deployments (source accounts only). Requires organization_id to be set."
  default     = ""

  validation {
    condition     = var.folder_id == "" || can(regex("^[0-9]{10,20}$", var.folder_id))
    error_message = "Folder ID must be empty or a valid numeric folder ID (10-20 digits)."
  }
}

# =============================================================================
# Restore Account Configuration
# =============================================================================

variable "restore_account_name" {
  type        = string
  description = "Display name for the restore account in Eon. Defaults to 'GCP-{project_id}'."
  default     = null
}

variable "host_project_id" {
  type        = string
  description = "The host project ID for Shared VPC (restore accounts only). When provided, grants permissions to use shared subnets from the host project."
  default     = ""

  validation {
    condition     = var.host_project_id == "" || can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", var.host_project_id))
    error_message = "Host project ID must be empty or a valid GCP project ID."
  }
}

variable "firestore_location" {
  type        = string
  description = "The Firestore location for Eon command results (restore accounts only)."
  default     = "nam5"
}

variable "eon_restore_regions" {
  type        = list(string)
  description = "List of GCP regions where restore is supported."
  default = [
    # US regions
    "us-east1", "us-east4", "us-east5", "us-central1", "us-west1", "us-west2", "us-west3", "us-west4", "us-south1",
    # Europe regions
    "europe-west1", "europe-west2", "europe-west3", "europe-west4", "europe-west6", "europe-west8", "europe-west9", "europe-west10", "europe-west12", "europe-north1", "europe-central2", "europe-southwest1",
    # Asia regions
    "asia-east1", "asia-east2", "asia-northeast1", "asia-northeast2", "asia-northeast3", "asia-south1", "asia-south2", "asia-southeast1", "asia-southeast2",
    # Other regions
    "australia-southeast1", "australia-southeast2", "southamerica-east1", "southamerica-west1", "northamerica-northeast1", "northamerica-northeast2", "me-west1", "me-central1", "me-central2", "africa-south1"
  ]
}

# =============================================================================
# Feature Toggles
# =============================================================================

variable "enable_gcs" {
  type        = bool
  description = "Enable GCS (Google Cloud Storage) permissions."
  default     = true
}

variable "enable_gcs_bucket_notification_management" {
  type        = bool
  description = "Allow Eon to manage GCS bucket notifications for Change Data Capture (CDC) backup. Requires enable_gcs = true. Source accounts only."
  default     = false
}

variable "enable_gce" {
  type        = bool
  description = "Enable GCE (Google Compute Engine) permissions."
  default     = true
}

variable "enable_cloudsql" {
  type        = bool
  description = "Enable CloudSQL permissions."
  default     = true
}

variable "enable_bigquery" {
  type        = bool
  description = "Enable BigQuery permissions."
  default     = true
}
