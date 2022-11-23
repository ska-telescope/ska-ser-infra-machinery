module "nexus" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
<<<<<<< HEAD
    name  = join("-", [var.datacentre, var.environment, var.service])
    image = "ubuntu-jammy-22.04"
=======
    name         = join("-", [var.datacentre, var.environment, var.service])
    image        = "ubuntu-jammy-22.04"
    applications = ["nexus"]
>>>>>>> origin/main
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
    applications = ["nexus"]
  }
}
