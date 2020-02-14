resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.public.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-ACL-Public"
      "Scheme"  = "public"
      "EnvName" = var.name
    }
  )
}

###########
# EGRESS
###########

# resource "aws_network_acl_rule" "out_public_local" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 1
#   egress         = true
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.default.cidr_block
#   from_port      = 0
#   to_port        = 0
# }

resource "aws_network_acl_rule" "out_public_world" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

###########
# INGRESS
###########

resource "aws_network_acl_rule" "in_public_local" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 1
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_vpc.default.cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "in_public_tcp" {
  count          = length(var.public_nacl_inbound_tcp_ports)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.public_nacl_inbound_tcp_ports[count.index]
  to_port        = var.public_nacl_inbound_tcp_ports[count.index]
}

resource "aws_network_acl_rule" "in_public_tcp_return" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 201
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_public_udp" {
  count          = length(var.public_nacl_inbound_udp_ports)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 301
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.public_nacl_inbound_udp_ports[count.index]
  to_port        = var.public_nacl_inbound_udp_ports[count.index]
}

resource "aws_network_acl_rule" "in_public_udp_return" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 401
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_public_icmp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 501
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 0
  icmp_code      = -1
}

resource "aws_network_acl_rule" "in_public_from_private" {
  count          = length(aws_subnet.private.*.cidr_block)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 601
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = 0
  to_port        = 0
}
