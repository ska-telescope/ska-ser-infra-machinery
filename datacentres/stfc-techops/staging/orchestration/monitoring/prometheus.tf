module "prometheus" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name = join("-", [var.datacentre, var.environment, var.service, "prometheus"])
    flavor       = "l3.micro"
    image        = "ubuntu-2004-lts"
    applications = ["prometheus", "thanos_sidecar", "grafana", "node_exporter"]
    volumes = [
      {
        mount_point = "/var/lib/containers"
        name        = "containers"
        size        = 20
      },
      {
        mount_point = "/var/lib/prometheus"
        name        = "prometheus_wal"
        size        = 200
      }
    ]
  }
}
