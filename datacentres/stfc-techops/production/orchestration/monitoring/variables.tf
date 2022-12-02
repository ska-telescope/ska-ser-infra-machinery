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

variable "openstack" {
  type = object({
    cloud      = string
    project_id = string
  })
}

variable "defaults" {
  type = object({
    availability_zone   = string
    flavor              = string
    image               = string
    keypair             = string
    network             = string
    jump_host           = optional(string)
    floating_ip_network = optional(string)
    vpn_cidr_blocks     = optional(list(string))
  })
  description = "Set of default values used when creating OpenStack instances"
}
