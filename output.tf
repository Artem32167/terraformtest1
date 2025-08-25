output "name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "vnet" {
  value = azurerm_virtual_network.vnet.name
}

output "rgfor_each" {
  value = [for v in azurerm_resource_group.rg2 : v.name]
}

output "rg_names" {
  value = [for name in var.rg_names : "rg-${name}-lab"]
}

output "keeper" {
  value = random_id.pip_suffix.hex
}

output "sql_password_from_kv" {
  value     = data.azurerm_key_vault_secret.sql_admin_pwd.value
  sensitive = true
}
