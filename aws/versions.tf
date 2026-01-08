terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws]
    }
    eon = {
      source                = "eon-io/eon"
      version               = "~> 2.0"
      configuration_aliases = [eon]
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
