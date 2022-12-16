module "thanos" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name         = join("-", [var.datacentre, var.environment, var.service, var.ci_pipeline_id, "thanos"])
    flavor       = "l3.micro"
    image        = "ubuntu-2004-lts"
    applications = ["thanos", "node_exporter"]
    volumes = [
      {
        mount_point = "/var/lib/containers"
        name        = "containers"
        size        = 10
      },
      {
        mount_point = "/etc/thanos/data/dir"
        name        = "thanos_data"
        size        = 10
      },
      {
        mount_point = "/etc/thanos/thanos-compact"
        name        = "thanos_compact"
        size        = 10
      }
    ]
  }
}
