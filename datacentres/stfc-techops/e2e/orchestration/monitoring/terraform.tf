# ---------------------- Config ---------------------- #
terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~>1.2.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~>1.48.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}
# --------------------------------------------------- #

# -------------------- Providers -------------------- #
provider "openstack" {
  cloud     = var.openstack.cloud
  tenant_id = var.openstack.project_id
}
# --------------------------------------------------- #
