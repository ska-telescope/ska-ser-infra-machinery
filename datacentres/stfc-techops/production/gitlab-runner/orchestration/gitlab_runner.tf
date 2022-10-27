module "gitlab_runner" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name   = "ska-techops-iac-gitlab-runner"
    flavor = "c3.large"
    image  = "ubuntu-jammy-22.04"
  }
}
