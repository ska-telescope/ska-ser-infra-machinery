module "thanos" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name = "thanos"
    image = "ubuntu-2004-lts"
    applications = ["thanos", "node_exporter"] 
    volumes = [ 
      {
        mount_point = "/var/lib/containers"
        name = "containers"
        size = 20
      },
      {
        mount_point = "/etc/thanos/data/dir"
        name = "thanos_data"
        size = 50
      },
       {
        mount_point = "/etc/thanos/thanos-compact"
        name = "thanos_compact"
        size = 50
      }  
    ]
  }

  
}