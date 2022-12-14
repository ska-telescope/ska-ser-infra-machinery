module "ceph_cluster" {
  source   = "../../../../../ska-ser-orchestration/openstack-ceph-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  ceph = {
    name = join("-", [var.datacentre, var.environment, var.service])
    master = {
      size             = 3
      data_volume_size = 10,
      wal_volume_size  = 10,
      flavor           = "c3.large"
      image            = "ubuntu-focal-20.04-nogui"
    }
    worker = {
      size = 0
    }
  }
}
