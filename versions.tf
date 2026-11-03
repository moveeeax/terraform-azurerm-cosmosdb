terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 4.78.0 is the floor because it is the first release with
      # local_authentication_enabled, the only name 5.x accepts after
      # local_authentication_disabled was removed in 5.0. The ceiling keeps the
      # next major from being picked up before it has been checked.
      version = ">= 4.78.0, < 6.0"
    }
  }
}
