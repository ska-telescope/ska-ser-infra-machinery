
module "clusterapi" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name            = "clusterapi" # use an unique name
    flavor          = "l3.micro"
    image           = "ubuntu-jammy-22.04"
    security_groups = ["default"]
    metadata = {
      type      = "k8s"
      service   = "clusterapi"
      component = "management"
    }

    volumes = []
  }
}

