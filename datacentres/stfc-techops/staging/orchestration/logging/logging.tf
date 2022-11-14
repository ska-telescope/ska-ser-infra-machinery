module "elasticsearch" {
  source   = "../../../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  elasticsearch = {
    name = join("-", [var.datacentre, var.environment, var.service])
    master = {
      size               = 1
      data_volume_size   = 100
      docker_volume_size = 20
    }
    data = {
      size               = 1
      data_volume_size   = 100
      docker_volume_size = 20
    }
    kibana = {
      size = 0
    }
    loadbalancer = {
      deploy             = true
      docker_volume_size = 20
      floating_ip = {
        create = false
      }
    }
  }
}