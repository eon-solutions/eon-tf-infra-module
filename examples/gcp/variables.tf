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

variable "eon_account_id" {
  type        = string
  description = "Eon account UUID"
}

# =============================================================================
# GCP Configuration
# =============================================================================

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
  default     = "us-central1"
}

variable "control_plane_service_account" {
  type        = string
  description = "GCP Workload Identity service account email for Eon control plane. Provided by Eon."
}

variable "scanning_project_id" {
  type        = string
  description = "GCP project that contains the eon-scan-* service account. Provided by Eon."
}
