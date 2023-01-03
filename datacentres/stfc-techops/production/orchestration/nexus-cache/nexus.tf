module "nexus" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name         = join("-", [var.datacentre, var.environment, var.service])
    flavor       = "c3.medium"
    applications = ["nexus"]
    volumes = [
      {
        mount_point = "/var/lib/docker"
        name        = "docker"
        size        = 20
      },
      {
        mount_point = "/var/lib/nexus"
        name        = "nexus-data"
        size        = 500
      }
    ]
  }
}
