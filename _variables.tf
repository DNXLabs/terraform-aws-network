variable "max_az" {
  type        = number
  default     = 3
  description = "Max number of AZs"
}

variable "name" {
  type        = string
  description = "Name prefix for the resources of this stack"
}

variable "cf_export_name" {
  type        = string
  default     = ""
  description = "Name prefix for the export resources of the cloud formation output"
}

variable "vpc_cidr" {
  type        = string
  description = "Network CIDR for the VPC"
}

variable "nat" {
  type        = bool
  default     = true
  description = "Deploy NAT instance(s)"
}

variable "multi_nat" {
  type        = bool
  default     = false
  description = "Number of NAT Instances, 'true' will yield one per AZ while 'false' creates one NAT"
}

variable "newbits" {
  type        = number
  default     = 5
  description = "Number of bits to add to the vpc cidr when building subnets"
}

variable "vpc_cidr_summ" {
  type        = string
  default     = "/0"
  description = "Define cidr used to summarize subnets by tier"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags to attach to resources"
}

variable "public_netnum_offset" {
  type        = number
  default     = 0
  description = "Start with this subnet for public ones, plus number of AZs"
}

variable "private_netnum_offset" {
  type        = number
  default     = 5
  description = "Start with this subnet for private ones, plus number of AZs"
}

variable "secure_netnum_offset" {
  type        = number
  default     = 10
  description = "Start with this subnet for secure ones, plus number of AZs"
}

variable "transit_netnum_offset" {
  type        = number
  default     = 15
  description = "Start with this subnet for secure ones, plus number of AZs"
}

variable "firewall_netnum_offset" {
  type        = number
  default     = 14
  description = "Start with this subnet for secure ones, plus number of AZs"
}

variable "firewall_custom_rules" {
  type        = list(string)
  default     = []
  description = "The stateful rule group rules specifications in Suricata file format, with one rule per line"
}

variable "firewall_custom_rule_arn" {
  type        = list(string)
  default     = []
  description = "The stateful rule group arn created outside the module"
}

variable "transit_subnet" {
  type        = bool
  default     = false
  description = "Create a transit subnet for VPC peering (only central account)"
}

variable "public_nacl_inbound_tcp_ports" {
  type        = list(string)
  default     = ["80", "443", "22", "1194"]
  description = "TCP Ports to allow inbound on public subnet via NACLs (this list cannot be empty)"
}

variable "public_nacl_outbound_tcp_ports" {
  type        = list(string)
  default     = ["0"]
  description = "TCP Ports to allow outbound to external services (use [0] to allow all ports)"
}

variable "public_nacl_inbound_udp_ports" {
  type        = list(string)
  default     = []
  description = "UDP Ports to allow inbound on public subnet via NACLs (this list cannot be empty)"
}

variable "public_nacl_outbound_udp_ports" {
  type        = list(string)
  default     = ["0"]
  description = "UDP Ports to allow outbound to external services (use [0] to allow all ports)"
}

variable "public_nacl_icmp" {
  type        = bool
  default     = true
  description = "Allows ICMP traffic to and from the public subnet"
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
  type        = bool
  default     = true
  description = "Enable or disable VPC Flow Logs"
}

variable "vpc_flow_logs_retention" {
  type        = number
  default     = 365
  description = "Retention in days for VPC Flow Logs CloudWatch Log Group"
}

variable "vpc_endpoint_s3_gateway" {
  type        = bool
  default     = true
  description = "Enable or disable VPC Endpoint for S3 Gateway"
}

variable "vpc_endpoint_dynamodb_gateway" {
  type        = bool
  default     = true
  description = "Enable or disable VPC Endpoint for DynamoDB (Gateway)"
}

variable "vpc_endpoint_s3_policy" {
  type        = string
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
  type = list(object(
    {
      name          = string
      policy        = optional(string)
      allowed_cidrs = optional(list(string))
    }
  ))
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

variable "name_suffix" {
  type        = string
  default     = ""
  description = "Adds a name suffix to all resources created"
}
variable "name_pattern" {
  type        = string
  default     = "default"
  description = "Name pattern to use for resources. Options: default, kebab"
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
  name_suffix = var.name_suffix != "" ? "-${var.name_suffix}" : ""

  names = {
    default = {
      db_subnet          = "%s-DBSubnet%s",
      nacl_private       = "%s-ACL-Private%s",
      nacl_public        = "%s-ACL-Public%s",
      nacl_secure        = "%s-ACL-Secure%s",
      nacl_transit       = "%s-ACL-Transit%s",
      eip                = "%s-EIP-%s%s",
      natgw              = "%s-NATGW-%s%s",
      subnet_private     = "%s-Subnet-Private-%s%s",
      routetable_private = "%s-RouteTable-Private-%s%s",
      subnet_public      = "%s-Subnet-Public-%s%s",
      routetable_public  = "%s-RouteTable-Public%s",
      subnet_secure      = "%s-Subnet-Secure-%s%s",
      routetable_secure  = "%s-RouteTable-Secure%s",
      subnet_transit     = "%s-Subnet-Transit-%s%s",
      routetable_transit = "%s-RouteTable-Transit%s",
      endpoint_dynamodb  = "%s-DynamoDB-Endpoint%s",
      endpoint_s3        = "%s-S3-Endpoint%s",
      endpoint           = "%s-%s-Endpoint%s",
      sg_endpoint        = "%s-%s-VPC-endpoint-sg%s",
      cwlog              = "%s-VPC-Flow-LogGroup%s"
      cwlog_iam_role     = "%s-%s-VPC-flow-logs%s"
      vpc                = "%s-VPC%s",
      ig                 = "%s-IG%s",
    }
    kebab = {
      db_subnet          = "%s-db-subnet%s",
      nacl_private       = "%s-acl-private%s",
      nacl_public        = "%s-acl-public%s",
      nacl_secure        = "%s-acl-secure%s",
      nacl_transit       = "%s-acl-transit%s",
      eip                = "%s-eip-%s%s",
      natgw              = "%s-natgw-%s%s",
      subnet_private     = "%s-subnet-private-%s%s",
      routetable_private = "%s-routetable-private-%s%s",
      subnet_public      = "%s-subnet-public-%s%s",
      routetable_public  = "%s-routetable-public%s",
      subnet_secure      = "%s-subnet-secure-%s%s",
      routetable_secure  = "%s-routetable-secure%s",
      subnet_transit     = "%s-subnet-transit-%s%s",
      routetable_transit = "%s-routetable-transit%s",
      endpoint_dynamodb  = "%s-dynamodb-endpoint%s",
      endpoint_s3        = "%s-s3-endpoint%s",
      endpoint           = "%s-%s-endpoint%s",
      sg_endpoint        = "%s-%s-endpoint-sg%s",
      cwlog              = "%s-vpc-flowlogs-loggroup%s"
      cwlog_iam_role     = "%s-%s-vpc-flowlogs-iamrole%s"
      vpc                = "%s-vpc%s",
      ig                 = "%s-ig%s",
    }
  }
}
