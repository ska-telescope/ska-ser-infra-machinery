variable "datacentre" {
  type        = string
  description = "The datacentre name"
}

variable "environment" {
  type        = string
  description = "The environment name"
}

variable "service" {
  type        = string
  description = "The orchestration service name"
}

variable "ci_pipeline_id" {
  type        = string
  description = "The id of the ci pipeline"
}

variable "openstack" {
  type = object({
    cloud      = string
    project_id = string
  })
}

variable "defaults" {
  type = object({
    availability_zone = string
    flavor            = string
    jump_host         = string
    image             = string
    keypair           = string
    network           = string
  })
  description = "Set of default values used when creating OpenStack instances"
}