output "vpc_id" {
  value       = aws_vpc.default.id
  description = "ID for VPC created"
}

output "cidr_block" {
  value       = aws_vpc.default.cidr_block
  description = "CIDR for VPC created"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.default.id
  description = "ID of Internet Gateway created"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "public_subnet_cidrs" {
  value       = aws_subnet.public[*].cidr_block
  description = "List of public subnet CIDRs"
}

output "firewall_subnet_cidrs" {
  value       = aws_subnet.firewall[*].cidr_block
  description = "List of firewall subnet CIDRs"
}

output "firewall_subnet_ids" {
  value       = aws_subnet.firewall[*].id
  description = "List of firewall subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of private subnet IDs"
}

output "private_subnet_cidrs" {
  value       = aws_subnet.private[*].cidr_block
  description = "List of private subnet CIDRs"
}

output "secure_subnet_ids" {
  value       = aws_subnet.secure[*].id
  description = "List of secure subnet IDs"
}

output "secure_subnet_cidrs" {
  value       = aws_subnet.secure[*].cidr_block
  description = "List of secure subnet CIDRs"
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.nat_gw[*].id
  description = "List of NAT Gateway IDs"
}

output "db_subnet_group_id" {
  value = aws_db_subnet_group.secure.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private[*].id
}

output "secure_route_table_id" {
  value = aws_route_table.secure.id
}

output "transit_route_table_id" {
  value = aws_route_table.transit[*].id
}

output "public_nacl_id" {
  value = aws_network_acl.public.id
}

output "private_nacl_id" {
  value = aws_network_acl.private.id
}

output "secure_nacl_id" {
  value = aws_network_acl.secure.id
}

output "transit_nacl_id" {
  value = aws_network_acl.transit[*].id
}

output "private_subnets" {
  value = aws_subnet.private
}

output "public_subnets" {
  value = aws_subnet.public
}

output "secure_subnets" {
  value = aws_subnet.secure
}

output "transit_subnets" {
  value = var.transit_subnet ? aws_subnet.transit : null
}

output "public_nacls" {
  value = {
    "acl" : aws_network_acl.private
    "egress" : {
      "out_public_local" : aws_network_acl_rule.out_public_local
      "out_public_tcp" : aws_network_acl_rule.out_public_tcp
      "out_public_tcp_return" : aws_network_acl_rule.out_public_tcp_return
      "out_public_udp" : aws_network_acl_rule.out_public_udp
      "out_public_icmp" : aws_network_acl_rule.out_public_icmp
    }
    "ingress" : {
      "in_public_local" : aws_network_acl_rule.in_public_local
      "in_public_tcp" : aws_network_acl_rule.in_public_tcp
      "in_public_tcp_return" : aws_network_acl_rule.in_public_tcp_return
      "in_public_udp" : aws_network_acl_rule.in_public_udp
      "in_public_udp_return" : aws_network_acl_rule.in_public_udp_return
      "in_public_icmp_reply" : aws_network_acl_rule.in_public_icmp_reply
      "in_public_from_private" : aws_network_acl_rule.in_public_from_private
    }
  }
}

output "private_nacls" {
  value = {
    "acl" : aws_network_acl.private
    "egress" : {
      "out_private_to_world_tcp" : aws_network_acl_rule.out_private_to_world_tcp
      "out_private_to_world_udp" : aws_network_acl_rule.out_private_to_world_udp
      "out_private_from_world_icmp" : aws_network_acl_rule.out_private_from_world_icmp
      "out_private_from_private" : aws_network_acl_rule.out_private_from_private
      "out_private_from_public" : aws_network_acl_rule.out_private_from_public
      "out_private_from_secure" : aws_network_acl_rule.out_private_from_secure
    }
    "ingress" : {
      "in_private_from_world_tcp_return" : aws_network_acl_rule.in_private_from_world_tcp_return
      "in_private_from_world_udp_return" : aws_network_acl_rule.in_private_from_world_udp_return
      "in_private_from_world_icmp_reply" : aws_network_acl_rule.in_private_from_world_icmp_reply
      "in_private_from_private" : aws_network_acl_rule.in_private_from_private
      "in_private_from_public" : aws_network_acl_rule.in_private_from_public
      "in_private_from_secure" : aws_network_acl_rule.in_private_from_secure
    }
  }
}

output "secure_nacls" {
  value = {
    "acl" : aws_network_acl.secure
    "egress" : {
      "out_secure_to_secure" : aws_network_acl_rule.out_secure_to_secure
      "out_secure_to_private" : aws_network_acl_rule.out_secure_to_private
      "out_secure_to_transit" : var.transit_subnet ? aws_network_acl_rule.out_secure_to_transit[0] : {}
      "out_secure_to_s3" : var.vpc_endpoint_s3_gateway ? aws_network_acl_rule.out_secure_to_s3 : []
    }
    "ingress" : {
      "in_secure_from_secure" : aws_network_acl_rule.in_secure_from_secure
      "in_secure_from_private" : aws_network_acl_rule.in_secure_from_private
      "in_secure_from_transit" : var.transit_subnet ? aws_network_acl_rule.in_secure_from_transit[0] : {}
      "in_secure_from_s3" : var.vpc_endpoint_s3_gateway ? aws_network_acl_rule.in_secure_from_s3 : []
    }
  }
}

output "secure_db_subnet" {
  value = aws_db_subnet_group.secure
}

output "nat_gateway" {
  value = aws_nat_gateway.nat_gw
}