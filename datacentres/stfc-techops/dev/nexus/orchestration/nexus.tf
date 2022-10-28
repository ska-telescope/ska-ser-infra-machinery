module "nexus" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name   = "nexus-bang-22"
    flavor = "c3.medium"
    image  = "ubuntu-bionic-18.04-gui"
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
