# ---------------------- Config ---------------------- #
terraform {
  required_version = "~>1.3.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~>1.49.0"
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
