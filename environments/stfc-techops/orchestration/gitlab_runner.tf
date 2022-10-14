module "gitlab_runner" {
  source   = "../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name   = "iac-gitlab-runner"
    flavor = "c3.large"
    image  = "ubuntu-2004-lts"
    volumes = [
      {
        name        = "docker"
        mount_point = "/var/lib/docker"
        size        = 20
      }
    ]
  }
}
