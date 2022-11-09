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
    jump_host           = string
    image               = string
    keypair             = string
    network             = string
    floating_ip_network = optional(string)
  })
  description = "Set of default values used when creating OpenStack instances"
}
