resource "aws_network_acl" "secure" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.secure.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-ACL-Secure"
      "Scheme"  = "secure"
      "EnvName" = var.name
    }
  )
}

resource "aws_network_acl_rule" "in_secure_from_secure" {
  count          = length(aws_subnet.secure.*.cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 1
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.secure[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_secure_to_secure" {
  count          = length(aws_subnet.secure.*.cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 1
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.secure[count.index].cidr_block
}

resource "aws_network_acl_rule" "in_secure_from_private_tcp" {
  count          = length(aws_subnet.private.*.cidr_block) * length(var.secure_nacl_inbound_tcp_ports)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index % length(aws_subnet.private.*.cidr_block)].cidr_block
  from_port      = var.secure_nacl_inbound_tcp_ports[count.index % length(var.secure_nacl_inbound_tcp_ports)]
  to_port        = tonumber(var.secure_nacl_inbound_tcp_ports[count.index % length(var.secure_nacl_inbound_tcp_ports)]) == 0 ? "65535" : var.secure_nacl_inbound_tcp_ports[count.index % length(var.secure_nacl_inbound_tcp_ports)]
}

resource "aws_network_acl_rule" "out_secure_to_private_tcp_return" {
  count          = length(aws_subnet.private.*.cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_secure_from_private_udp" {
  count          = length(aws_subnet.private.*.cidr_block) * length(var.secure_nacl_inbound_udp_ports)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 201
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index % length(aws_subnet.private.*.cidr_block)].cidr_block
  from_port      = var.secure_nacl_inbound_udp_ports[count.index % length(var.secure_nacl_inbound_udp_ports)]
  to_port        = tonumber(var.secure_nacl_inbound_udp_ports[count.index % length(var.secure_nacl_inbound_udp_ports)]) == 0 ? "65535" : var.secure_nacl_inbound_udp_ports[count.index % length(var.secure_nacl_inbound_udp_ports)]
}

resource "aws_network_acl_rule" "out_secure_to_private_udp_return" {
  count          = length(aws_subnet.private.*.cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 201
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_secure_from_transit" {
  count          = var.transit_subnet ? length(aws_subnet.transit.*.cidr_block) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 301
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.transit[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_secure_to_transit" {
  count          = var.transit_subnet ? length(aws_subnet.transit.*.cidr_block) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 201
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.transit[count.index].cidr_block
}

#############
# S3 Endpoint
#############
resource "aws_network_acl_rule" "in_secure_from_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 501
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_secure_to_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 501
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = 443
  to_port        = 443
}
