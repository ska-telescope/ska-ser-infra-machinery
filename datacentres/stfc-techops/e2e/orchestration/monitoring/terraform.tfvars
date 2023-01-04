# OpenStack Cloud Configurations
openstack = {
  cloud      = "openstack"
  project_id = "b5069610560e42bb837183ad5cd58ec0"
}

# OpenStack Instance defaults for the given OpenStack Cloud
defaults = {
  flavor              = "c3.large"
  image               = "ubuntu-focal-20.04-nogui"
  availability_zone   = "ceph"
  network             = "SKA-TechOps-Private"
  keypair             = "ska-techops"
  floating_ip_network = "External"
  jump_host           = "01a68010-cc61-4396-9690-cb7263d2412d"
}
