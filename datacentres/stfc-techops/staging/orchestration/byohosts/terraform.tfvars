# OpenStack Cloud Configurations
openstack = {
  cloud      = "skatechops"
  project_id = "b5069610560e42bb837183ad5cd58ec0"
}

# OpenStack Instance defaults for the given OpenStack Cloud
defaults = {
  flavor                = "l3.nano"
  image                 = "ubuntu-focal-20.04-nogui"
  security_groups       = ["default"]
  port_security_enabled = false
  keypair               = "ska-techops"
  network               = "SKA-TechOps-ClusterAPI1"
  jump_host             = "01a68010-cc61-4396-9690-cb7263d2412d"
  availability_zone     = "ceph"
}
