terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 3.83, < 4.0"
      configuration_aliases = [azurerm]
    }
    azuread = {
      source                = "hashicorp/azuread"
      version               = "~> 2.0"
      configuration_aliases = [azuread]
    }
    eon = {
      source                = "eon-io/eon"
      version               = "~> 2.0"
      configuration_aliases = [eon]
    }
  }
}
