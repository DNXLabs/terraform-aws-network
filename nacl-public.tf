locals {
  public_subnet_ip      = split("/", element(aws_subnet.public[*].cidr_block, length(aws_subnet.public[*].cidr_block) - 1))[0]
  public_subnet_summary = var.vpc_cidr_summ != "/0" ? "${cidrhost("${local.public_subnet_ip}${var.vpc_cidr_summ}", 0)}${var.vpc_cidr_summ}" : aws_vpc.default.cidr_block
}
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].nacl_public, var.name, local.name_suffix)
      "Scheme"  = "public"
      "EnvName" = var.name
    }
  )
}

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

resource "aws_network_acl_rule" "out_public_local" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 1
  egress         = true
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
  to_port        = tonumber(var.public_nacl_inbound_tcp_ports[count.index] == 0 ? "65535" : var.public_nacl_inbound_tcp_ports[count.index])
}

resource "aws_network_acl_rule" "out_public_tcp" {
  count          = length(var.public_nacl_outbound_tcp_ports)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.public_nacl_outbound_tcp_ports[count.index]
  to_port        = tonumber(var.public_nacl_outbound_tcp_ports[count.index]) == 0 ? "65535" : var.public_nacl_outbound_tcp_ports[count.index]
}

resource "aws_network_acl_rule" "in_public_tcp_return" {
  # This is required for internet access
  network_acl_id = aws_network_acl.public.id
  rule_number    = 201
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_public_tcp_return" {
  # This is required inbound access
  network_acl_id = aws_network_acl.public.id
  rule_number    = 201
  egress         = true
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

resource "aws_network_acl_rule" "out_public_udp" {
  count          = length(var.public_nacl_inbound_udp_ports)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 301
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.public_nacl_outbound_udp_ports[count.index]
  to_port        = var.public_nacl_outbound_udp_ports[count.index]
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

resource "aws_network_acl_rule" "in_public_icmp_reply" {
  count          = var.public_nacl_icmp ? 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 501
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 0
  icmp_code      = -1
}

resource "aws_network_acl_rule" "out_public_icmp" {
  count          = var.public_nacl_icmp ? 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 501
  egress         = true
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 8
  icmp_code      = -1
}

resource "aws_network_acl_rule" "in_public_from_private" {
  count          = var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.private[*].cidr_block)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 601
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.private_subnet_summary : aws_subnet.private[count.index].cidr_block
  from_port      = 0
  to_port        = 0
}
