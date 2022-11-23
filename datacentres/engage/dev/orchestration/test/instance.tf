module "instance" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name         = join("-", [var.datacentre, var.environment, var.service, "instance"])
    applications = ["reverseproxy", "nexus"]
    floating_ip = {
      create  = true
      network = "external"
    }
  }
}
