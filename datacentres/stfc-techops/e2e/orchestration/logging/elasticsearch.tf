module "elasticsearch" {
  source   = "../../../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  elasticsearch = {
    name = var.group_name
    master = {
      size               = 1
      data_volume_size   = 10
      docker_volume_size = 10
    }
    data = {
      size               = 1
      data_volume_size   = 10
      docker_volume_size = 10
    }
    kibana = {
      size               = 1
      docker_volume_size = 10
    }
    loadbalancer = {
      deploy             = true
      docker_volume_size = 10
      floating_ip = {
        create = false
      }
    }
  }
}