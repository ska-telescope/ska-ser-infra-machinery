module "ceph_cluster" {
  source   = "../../../ska-ser-orchestration/openstack-ceph-cluster"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  ceph = {
    name = "ceph"
    master = {
      size             = 3
      data_volume_size = 10,
      wal_volume_size  = 10,
      flavor           = "c3.large"
      image            = "Ubuntu-20.04"
    }
    worker = {
      size = 0
    }
  }
}
