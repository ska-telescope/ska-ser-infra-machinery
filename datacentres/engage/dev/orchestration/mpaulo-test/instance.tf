module "instance" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name         = "mpaulo-test-instance"
    applications = ["reverseproxy","nexus"]
    floating_ip = {
      create  = true
      network = "external"
    }
  }
}
