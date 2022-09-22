module "central_logging" {
  source   = "../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  elasticsearch = {
    name   = "central-logging"
    master = {
      data_volume_size = 250
    }
    data = {
      size = 0
    }
    kibana = {
      size = 0
    }
  }
}


output "central_logging" {
  value = module.central_logging
}
