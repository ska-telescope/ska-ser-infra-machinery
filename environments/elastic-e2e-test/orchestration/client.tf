module "instance" {
  source   = "../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name = "${var.environment}-client"
  }
}