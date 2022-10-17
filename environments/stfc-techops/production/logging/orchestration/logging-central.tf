module "ska-techops-logging-central-prod" {
  source   = "../../../../../ska-ser-orchestration/openstack-elasticsearch-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  elasticsearch = {
    name   = "ska-techops-logging-central-prod"
    master = {}
    data = {}
    kibana = {}
    loadbalancer = {
      floating_ip = {
        address = "130.246.214.33"
        create = false
        network = "External"
      }
    }
  }
}