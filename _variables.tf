variable "max_az" {
  default     = 3
  description = "Max number of AZs"
}

variable "name" {
  description = "Name prefix for the resources of this stack"
}

variable "cf_export_name" {
  default     = ""
  description = "Name prefix for the export resources of the cloud formation output"
}

variable "vpc_cidr" {
  description = "Network CIDR for the VPC"
}

variable "vpc_cidr_transit" {
  default     = "10.255.255.0/24"
  description = "Network CIDR for Transit subnets"
}

variable "multi_nat" {
  default     = false
  description = "Number of NAT Instances, 'true' will yield one per AZ while 'false' creates one NAT"
}

variable "newbits" {
  default     = 5
  description = "Number of bits to add to the vpc cidr when building subnets"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags to attach to resources"
}

variable "public_netnum_offset" {
  default     = 0
  description = "Start with this subnet for public ones, plus number of AZs"
}

variable "private_netnum_offset" {
  default     = 5
  description = "Start with this subnet for private ones, plus number of AZs"
}

variable "secure_netnum_offset" {
  default     = 10
  description = "Start with this subnet for secure ones, plus number of AZs"
}

variable "transit_netnum_offset" {
  default     = 15
  description = "Start with this subnet for secure ones, plus number of AZs"
}

variable "firewall_netnum_offset" {
  default     = 14
  description = "Start with this subnet for secure ones, plus number of AZs"
}

variable "firewall_custom_rules" {
  type        = list(string)
  default     = []
  description = "The stateful rule group rules specifications in Suricata file format, with one rule per line"
}

variable "transit_subnet" {
  default     = false
  description = "Create a transit subnet for VPC peering (only central account)"
}

variable "public_nacl_inbound_tcp_ports" {
  type        = list(string)
  default     = ["80", "443", "22", "1194"]
  description = "TCP Ports to allow inbound on public subnet via NACLs (this list cannot be empty)"
}

variable "public_nacl_inbound_udp_ports" {
  type        = list(string)
  default     = []
  description = "UDP Ports to allow inbound on public subnet via NACLs (this list cannot be empty)"
}

variable "transit_nacl_inbound_tcp_ports" {
  type        = list(string)
  default     = ["1194"]
  description = "TCP Ports to allow inbound on transit subnet via NACLs (this list cannot be empty)"
}

variable "transit_nacl_inbound_udp_ports" {
  type        = list(string)
  default     = ["1194"]
  description = "UDP Ports to allow inbound on transit subnet via NACLs (this list cannot be empty)"
}

variable "vpc_flow_logs" {
  default     = true
  description = "Enable or disable VPC Flow Logs"
}

variable "vpc_flow_logs_retention" {
  default     = 365
  description = "Retention in days for VPC Flow Logs CloudWatch Log Group"
}

variable "vpc_endpoint_s3_gateway" {
  type        = bool
  default     = true
  description = "Enable or disable VPC Endpoint for S3 Gateway"
}

variable "vpc_endpoint_s3_policy" {
  default     = <<POLICY
    {
        "Statement": [
            {
                "Action": "*","Effect": "Allow","Resource": "*","Principal": "*"
            }
        ]
    }
    POLICY
  description = "A policy to attach to the endpoint that controls access to the service"
}

variable "vpc_endpoints" {
  type        = list(string)
  default     = []
  description = "AWS services to create a VPC endpoint on private subnets for (e.g: ssm, ec2, ecr.dkr)"
}

variable "kubernetes_clusters" {
  type        = list(string)
  default     = []
  description = "List of kubernetes cluster names to creates tags in public and private subnets of this VPC"
}

variable "kubernetes_clusters_secure" {
  type        = list(string)
  default     = []
  description = "List of kubernetes cluster names to creates tags in secure subnets of this VPC"
}

variable "kubernetes_clusters_type" {
  type        = string
  default     = "shared"
  description = "Use either 'owned' or 'shared' for kubernetes cluster tags"
}

variable "byoip" {
  type        = bool
  default     = false
  description = "Enable module to use your own Elastic IPs (Bring Your Own IP)"
}

variable "eip_allocation_ids" {
  type        = list(string)
  default     = []
  description = "User-specified primary or secondary private IP address to associate with the Elastic IP address"
}

variable "network_firewall" {
  type        = bool
  default     = false
  description = "Enable or disable VPC Network Firewall"
}

variable "firewall_domain_list" {
  type        = list(any)
  default     = [".amazonaws.com", ".github.com"]
  description = "List the domain names you want to take action on."
}

variable "enable_firewall_default_rule" {
  type        = bool
  default     = true
  description = "Enable or disable the default stateful rule."
}
locals {
  kubernetes_clusters = zipmap(
    formatlist("kubernetes.io/cluster/%s", var.kubernetes_clusters),
    [for cluster in var.kubernetes_clusters : var.kubernetes_clusters_type]
  )
  kubernetes_clusters_secure = zipmap(
    formatlist("kubernetes.io/cluster/%s", var.kubernetes_clusters_secure),
    [for cluster in var.kubernetes_clusters_secure : var.kubernetes_clusters_type]
  )
}
