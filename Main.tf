resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = merge(var.tags, var.additional_tags)
}

resource "azurerm_resource_group" "imported-rg" {
  name     = "usual"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_public_ip" "vm_pip" {
  name                = var.vm-pip-name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic-name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

resource "azurerm_virtual_machine" "VM" {
  name                  = var.vm-name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.vm-name}-osdisk-001"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "devops-vm"
    admin_username = "azureuser"
    admin_password = "P@ssw0rd1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

module "rg" {
  source                     = "./modules/resource_group"
  resource_group_name_module = "devops-lab-rg"
  location_module            = "westeurope"
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "5.0.1"
  resource_group_name = module.rg.rg_name
  vnet_location       = module.rg.rg_locaton
  vnet_name           = "devops-lab-vnet"
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["devops-lab-subnet"]
}

module "nsg1" {
  source                  = "./modules/NSG"
  nsg_location            = module.rg.rg_locaton
  nsg_name                = "NSG_module"
  nsg_resource_group_name = module.rg.rg_name
}

output "monitoring_enabled" {
  value = var.enable_monitoring
}

resource "azurerm_resource_group" "rg2" {
  for_each = {
    for env, loc in var.environments :
    env => loc
    if env != "test"
  }
  name     = "rg-${each.key}-lab_foreach"
  location = each.value
}

resource "azurerm_resource_group" "rg3" {
  count    = length(var.rg_names)
  name     = "rg-${var.rg_names[count.index]}-lab_count"
  location = var.location2
}

# Random suffix for unique PIP name
resource "random_id" "pip_suffix" {
  byte_length = 2
  keepers = {
    generation = var.pip_generation
  }
}

resource "azurerm_public_ip" "pip_cbfd" {
  name                = "pip-cbfd-${random_id.pip_suffix.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_resource_group" "prod" {
  name     = var.rg_for_preventdestroy
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account" "logs" {
  name                            = "prodstoragelogs${random_integer.suffix.result}"
  resource_group_name             = azurerm_resource_group.prod.name
  location                        = azurerm_resource_group.prod.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

resource "azurerm_storage_account" "ignorechanges" {
  name                            = "ignorechanges${random_integer.suffix.result}"
  resource_group_name             = azurerm_resource_group.prod.name
  location                        = azurerm_resource_group.prod.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "terraform_data" "vm_epoch" {
  triggers_replace = {
    release = var.image_release
  }
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet-${random_string.suffix.result}"
  address_space       = ["10.42.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.prod.name
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.42.1.0/24"]
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.prod.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }

  lifecycle {
    # Any change to the subnet (e.g., prefix/name) will force a NIC replacement
    replace_triggered_by = [
      azurerm_subnet.app.id
    ]
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.prod.name
  location                        = var.location
  size                            = "Standard_B2s"
  admin_username                  = "azureuser"
  disable_password_authentication = false
  admin_password                  = "LabP@ssword123!"

  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  # Use a common Marketplace image for the lab
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  lifecycle {
    # 1) Bump terraform_data.vm_epoch → replace VM
    # 2) If NIC is replaced (ID changes) → replace VM
    replace_triggered_by = [
      terraform_data.vm_epoch.id,
      azurerm_network_interface.vm_nic.id
    ]
  }
}

resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "CustomScript"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  settings = jsonencode({
    commandToExecute = "curl http://example.com"
  })

  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]
}

resource "azurerm_network_security_group" "nsg_dynamic" {
  name                = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.prod.name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value.port)
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

data "azurerm_resource_group" "existing_rg" {
  name = "test-existing"
}

resource "azurerm_storage_account" "sa_inexisting_rg" {
  name                     = "storagedemo${random_string.suffix.result}"
  resource_group_name      = data.azurerm_resource_group.existing_rg.name
  location                 = data.azurerm_resource_group.existing_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}