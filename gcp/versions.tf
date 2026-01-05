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
