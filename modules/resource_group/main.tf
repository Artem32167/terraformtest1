resource "azurerm_resource_group" "rg" {
  location = var.location_module
  name     = var.resource_group_name_module
}