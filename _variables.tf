variable "name" {
  description = "Name prefix for the resources of this stack"
}

variable "vpc_cidr" {
  description = "Network CIDR for the VPC"
}

variable "multi_nat" {
  default     = false
  description = "Number of NAT Instances, 'true' will yield one per AZ while 'false' creates one NAT"
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

variable "public_nacl_inbound_tcp_ports" {
  type        = "list"
  default     = ["80", "443", "22", "1194"]
  description = "TCP Ports to allow inbound on public subnet via NACLs (this list cannot be empty)"
}

variable "public_nacl_inbound_udp_ports" {
  type        = "list"
  default     = ["1194"]
  description = "UDP Ports to allow inbound on public subnet via NACLs (this list cannot be empty)"
}

variable "secure_nacl_inbound_tcp_ports" {
  type        = "list"
  default     = ["5432", "3306", "1433", "1521", "2049"]
  description = "TCP Ports to allow inbound on secure subnet via NACLs (this list cannot be empty)"
}

variable "secure_nacl_inbound_udp_ports" {
  type        = "list"
  default     = []
  description = "UDP Ports to allow inbound on secure subnet via NACLs"
}
}
