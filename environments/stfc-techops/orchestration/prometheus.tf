
module "prometheus" {
  source   = "../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name = "prometheus_podman" # use an unique name
    flavor = "c3.large"
    image = "ubuntu-2004-lts"
    volumes = [ 
      {
        mount_point = "/var/lib/containers"
        name = "containers"
        size = 20
      },
      {
        mount_point = "/var/lib/prometheus"
        name = "prometheus_wal"
        size = 200
      } 
    ]
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [module.prometheus]

  create_duration = "30s"
}

output "prometheus" {
  value = module.prometheus
  
}
