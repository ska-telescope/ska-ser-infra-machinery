# OpenStack Cloud Configurations
openstack = {
  cloud      = "openstack"
  project_id = "0505002d0063496bb0dea54c2a89f356"
}

# OpenStack Instance defaults for the given OpenStack Cloud
defaults = {
  flavor            = "m1.large"
  image             = "Ubuntu-18.04"
  availability_zone = "nova"
  network           = "internal"
  keypair           = "ska-techops"
  jump_host         = "d3d5dcc8-9151-4892-82d8-4b766889c720"
}