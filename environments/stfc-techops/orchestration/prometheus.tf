
module "prometheus" {
  source   = "../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name = "prometheus_podman" # use an unique name
    #flavor = "l3.micro"
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

output "prometheus" {
  value = module.prometheus
  
}
