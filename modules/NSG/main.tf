resource "azurerm_network_security_group" "NSG1" {
  name                = var.nsg_name
  location            = var.nsg_location
  resource_group_name = var.nsg_resource_group_name
}