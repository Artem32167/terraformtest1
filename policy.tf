data "azurerm_resource_group" "scope" {
  name = "usual"
}

# 1) Custom policy: Require the `owner` tag on resources
resource "azurerm_policy_definition" "require_owner_tag" {
  name         = "require-owner-tag"
  policy_type  = "Custom"
  mode         = "Indexed" # evaluate resource properties (not classic)
  display_name = "Require the 'owner' tag on resources"
  description  = "Denies creation/update of any resource that doesn't include the 'owner' tag."

  metadata = jsonencode({
    category = "Tags"
  })

  # Deny when the 'owner' tag is missing or empty
  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags.owner", exists = "false" },
        { field = "tags.owner", equals = "" }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# 2) Assign the policy at the RG scope
resource "azurerm_resource_group_policy_assignment" "require_owner_tag_rg" {
  name                 = "require-owner-tag-rg"
  resource_group_id    = data.azurerm_resource_group.scope.id
  policy_definition_id = azurerm_policy_definition.require_owner_tag.id

  display_name = "Require 'owner' tag at RG scope"
  description  = "All resources in this RG must have tag 'owner'."
  # Optional niceties:
  # enforcement_mode = "Default"
  # non_compliance_message { content = "Tag 'owner' is required." }
}