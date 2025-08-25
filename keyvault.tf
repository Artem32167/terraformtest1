data "azuread_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.kv_name
  location                   = data.azurerm_resource_group.existing_rg.location
  resource_group_name        = data.azurerm_resource_group.existing_rg.name
  tenant_id                  = data.azuread_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
}

# If Terraform manages the secret
resource "azurerm_key_vault_secret" "sql_admin_pwd" {
  count        = var.manage_secret_in_tf ? 1 : 0
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault_access_policy.me]
}

resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = data.azuread_client_config.current.object_id

  # Grant what you need; here: manage secrets + read keys metadata/ops if needed
  secret_permissions      = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  key_permissions         = ["Get", "List"] # add "Sign","Verify","WrapKey","UnwrapKey" if required
  certificate_permissions = ["Get", "List"]
}

data "azurerm_key_vault_secret" "sql_admin_pwd" {
  name         = "sql-admin-password"
  key_vault_id = azurerm_key_vault.this.id
}