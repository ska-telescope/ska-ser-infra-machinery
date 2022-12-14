# OpenStack Cloud Configurations
openstack = {
  cloud      = "openstack"
  project_id = "b5069610560e42bb837183ad5cd58ec0"
}

# OpenStack Instance defaults for the given OpenStack Cloud
defaults = {
  flavor              = "c3.large"
  image               = "ubuntu-jammy-22.04"
  availability_zone   = "ceph"
  network             = "SKA-TechOps-Private"
  keypair             = "ska-techops"
  jump_host           = "01a68010-cc61-4396-9690-cb7263d2412d"
  floating_ip_network = "External"
  vpn_cidr_blocks = [
    "10.8.0.0/24",    # OpenVPN Server 1
    "10.9.0.0/24",    # OpenVPN Server 2
    "192.168.99.0/24" # SKA-TechOps-Private
  ]
}
