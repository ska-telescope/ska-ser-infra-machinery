module "central_logging" {
  source   = "../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  elasticsearch = {
    name   = "central_logging"
    master = {
      data_volume_size = 250,
      docker_volume_size = 20
    }
    data = {
      size = 0
    }
    kibana = {
      size = 0
    }
  }
}