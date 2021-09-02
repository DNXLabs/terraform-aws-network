resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.private.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-ACL-Private"
      "Scheme"  = "private"
      "EnvName" = var.name
    }
  )
}

resource "aws_network_acl_rule" "in_private_from_private" {
  count          = length(aws_subnet.private.*.cidr_block)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 1
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "out_private_from_private" {
  count          = length(aws_subnet.private.*.cidr_block)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 1
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "in_private_from_world_tcp_return" {
  count          = length(var.public_nacl_outbound_tcp_ports) > 0 ? 1 : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_private_to_world_tcp" {
  count          = length(var.public_nacl_outbound_tcp_ports)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.public_nacl_outbound_tcp_ports[count.index]
  to_port        = tonumber(var.public_nacl_outbound_tcp_ports[count.index]) == 0 ? "65535" : var.public_nacl_outbound_tcp_ports[count.index]
}

resource "aws_network_acl_rule" "in_private_from_world_udp_return" {
  count          = length(var.public_nacl_outbound_udp_ports) > 0 ? 1 : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = 201
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_private_to_world_udp" {
  count          = length(var.public_nacl_outbound_udp_ports)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 201
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.public_nacl_outbound_udp_ports[count.index]
  to_port        = tonumber(var.public_nacl_outbound_udp_ports[count.index]) == 0 ? "65535" : var.public_nacl_outbound_udp_ports[count.index]
}

resource "aws_network_acl_rule" "in_private_from_world_icmp_reply" {
  count          = var.public_nacl_icmp ? 1 : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = 301
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 0 # echo reply
  icmp_code      = -1
}

resource "aws_network_acl_rule" "out_private_from_world_icmp" {
  count          = var.public_nacl_icmp ? 1 : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = 301
  egress         = true
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 8 # echo
  icmp_code      = -1
}

resource "aws_network_acl_rule" "in_private_from_public_tcp" {
  count          = length(aws_subnet.public.*.cidr_block) * length(var.private_nacl_inbound_tcp_ports)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 401
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.public[count.index % length(aws_subnet.public.*.cidr_block)].cidr_block
  from_port      = var.private_nacl_inbound_tcp_ports[count.index % length(var.private_nacl_inbound_tcp_ports)]
  to_port        = tonumber(var.private_nacl_inbound_tcp_ports[count.index % length(var.private_nacl_inbound_tcp_ports)]) == 0 ? "65535" : var.private_nacl_inbound_tcp_ports[count.index % length(var.private_nacl_inbound_tcp_ports)]
}

resource "aws_network_acl_rule" "out_private_from_public_tcp_return" {
  count          = length(var.private_nacl_inbound_tcp_ports) > 0 ? length(aws_subnet.public.*.cidr_block) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 401
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.public[count.index].cidr_block
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_private_from_public_udp" {
  count          = length(aws_subnet.public.*.cidr_block) * length(var.private_nacl_inbound_udp_ports)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 501
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.public[count.index % length(aws_subnet.public.*.cidr_block)].cidr_block
  from_port      = var.private_nacl_inbound_udp_ports[count.index % length(var.private_nacl_inbound_udp_ports)]
  to_port        = tonumber(var.private_nacl_inbound_udp_ports[count.index % length(var.private_nacl_inbound_udp_ports)]) == 0 ? "65535" : var.private_nacl_inbound_udp_ports[count.index % length(var.private_nacl_inbound_udp_ports)]
}

resource "aws_network_acl_rule" "out_private_from_public_udp_return" {
  count          = length(var.private_nacl_inbound_udp_ports) > 0 ? length(aws_subnet.public.*.cidr_block) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 501
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.public[count.index].cidr_block
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_private_from_secure_tcp_return" {
  count          = length(var.private_nacl_inbound_tcp_ports) > 0 ? length(aws_subnet.secure.*.cidr_block) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 601
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.secure[count.index].cidr_block
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_private_from_secure_tcp" {
  count          = length(aws_subnet.secure.*.cidr_block) * length(var.secure_nacl_inbound_tcp_ports)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 601
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.secure[count.index % length(aws_subnet.secure.*.cidr_block)].cidr_block
  from_port      = var.secure_nacl_inbound_tcp_ports[count.index % length(var.secure_nacl_inbound_tcp_ports)]
  to_port        = tonumber(var.secure_nacl_inbound_tcp_ports[count.index % length(var.secure_nacl_inbound_tcp_ports)]) == 0 ? "65535" : var.secure_nacl_inbound_tcp_ports[count.index % length(var.secure_nacl_inbound_tcp_ports)]
}

resource "aws_network_acl_rule" "in_private_from_secure_udp_return" {
  count          = length(var.private_nacl_inbound_udp_ports) > 0 ? length(aws_subnet.secure.*.cidr_block) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 701
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.secure[count.index].cidr_block
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_private_from_secure_udp" {
  count          = length(aws_subnet.secure.*.cidr_block) * length(var.secure_nacl_inbound_udp_ports)
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 701
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.secure[count.index % length(aws_subnet.secure.*.cidr_block)].cidr_block
  from_port      = var.secure_nacl_inbound_udp_ports[count.index % length(var.secure_nacl_inbound_udp_ports)]
  to_port        = tonumber(var.secure_nacl_inbound_udp_ports[count.index % length(var.secure_nacl_inbound_udp_ports)]) == 0 ? "65535" : var.secure_nacl_inbound_udp_ports[count.index % length(var.secure_nacl_inbound_udp_ports)]
}

#############
# S3 Endpoint
#############
resource "aws_network_acl_rule" "in_private_from_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 801
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_private_to_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 801
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = 443
  to_port        = 443
}
