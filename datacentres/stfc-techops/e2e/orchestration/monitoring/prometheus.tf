module "prometheus" {
  source   = "../../../../../ska-ser-orchestration/openstack-instance"
  defaults = var.defaults
  providers = {
    openstack = openstack
  }

  configuration = {
    name         = join("-", [var.datacentre, var.environment, var.service, "prometheus", var.ci_pipeline_id])
    applications = ["prometheus", "thanos_sidecar", "grafana", "node_exporter"]
    volumes = [
      {
        mount_point = "/var/lib/containers"
        name        = "containers"
        size        = 10
      },
      {
        mount_point = "/var/lib/prometheus"
        name        = "prometheus_wal"
        size        = 10
      }
    ]
  }
}
