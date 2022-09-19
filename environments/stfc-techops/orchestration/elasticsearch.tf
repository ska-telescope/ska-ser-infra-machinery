module "elasticsearch" {
  source   = "../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  elasticsearch = {
    name   = "cental-monitoring"
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

output "elasticsearch" {
  value = module.elasticsearch
}
