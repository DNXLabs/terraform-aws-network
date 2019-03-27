variable "name" {
  description = "Name prefix for the resources of this stack"
}

variable "vpc_cidr" {
  description = "Network CIDR for the VPC"
}

variable "nat_count" {
  default     = 1
  description = "Number of NAT Gateways to create (usually 1 or the number of AZs)"
}

variable "newbits" {
  default     = 8
  description = "Number of bits to add to the vpc cidr when building subnets"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Extra tags to attach to resources"
}

variable "public_netnum_offset" {
  default     = 0
  description = "Start with this subnet for public ones, plus number of AZs"
}

variable "private_netnum_offset" {
  default     = 10
  description = "Start with this subnet for private ones, plus number of AZs"
}

variable "secure_netnum_offset" {
  default     = 20
  description = "Start with this subnet for secure ones, plus number of AZs"
}
