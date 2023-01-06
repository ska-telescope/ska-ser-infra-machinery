locals {
  instance_group_name = "byohosts"
}

module "instance_group" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance-group"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name = local.instance_group_name
    size = 7
  }
}
