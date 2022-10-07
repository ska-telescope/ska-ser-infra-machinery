module "elasticsearch" {
  source   = "../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  elasticsearch = {
    name = var.environment
    master = {
      size               = 3
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
    loadbalancer = {
      deploy             = false
      docker_volume_size = 10
      floating_ip = {
        create = true
      }
    }
  }
}