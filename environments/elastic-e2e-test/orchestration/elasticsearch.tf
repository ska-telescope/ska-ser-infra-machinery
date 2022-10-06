module "elasticsearch" {
  source   = "../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  # TODO: Set to 1 master and 1 data when playbook supports it

  elasticsearch = {
    name = var.environment
    master = {
      size               = 2
      data_volume_size   = 10
      docker_volume_size = 10
    }
    data = {
      size               = 0
      data_volume_size   = 10
      docker_volume_size = 10
    }
    kibana = {
      size               = 0
      docker_volume_size = 10
    }
  }
}