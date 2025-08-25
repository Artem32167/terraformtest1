provider "azurerm" {
  features {}
  subscription_id = "455b12fc-098f-4744-b3ac-cc70ea62fa26"
}
locals {
  environment = terraform.workspace
}