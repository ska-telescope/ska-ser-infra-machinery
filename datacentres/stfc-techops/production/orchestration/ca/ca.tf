module "ca" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name         = join("-", [var.datacentre, var.environment, var.service])
    flavor       = "l3.nano"
    keypair      = "ska-ser-ca"
  }
}