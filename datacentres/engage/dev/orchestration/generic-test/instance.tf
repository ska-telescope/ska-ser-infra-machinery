module "instance" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name         = "generic-test-instance"
    applications = ["reverseproxy", "nexus"]
    floating_ip = {
      create  = true
      network = "external"
    }
  }
}
