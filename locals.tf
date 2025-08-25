locals {
  prefix = "${var.env_name}-${var.location}"
  common_tags = {
    environment = var.env_name
    owner       = "artsemi"
    project     = "demo"
  }
}
