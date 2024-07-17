locals {
  transit_subnet_ip      = split("/", try(element(aws_subnet.transit[*].cidr_block, length(aws_subnet.transit[*].cidr_block) - 1), "0.0.0.0/0"))[0]
  transit_subnet_summary = var.vpc_cidr_summ != "/0" ? "${cidrhost("${local.transit_subnet_ip}${var.vpc_cidr_summ}", 0)}${var.vpc_cidr_summ}" : aws_vpc.default.cidr_block
}
resource "aws_network_acl" "transit" {
  count      = var.transit_subnet ? 1 : 0
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.transit[*].id

  tags = merge(
    var.tags,
    tomap({
      "Name"    = format(local.names[var.name_pattern].nacl_transit, var.name, local.name_suffix)
      "Scheme"  = "transit",
      "EnvName" = var.name
    })
  )
}

###########
# EGRESS
###########

# resource "aws_network_acl_rule" "out_transit_local" {
#   network_acl_id = aws_network_acl.transit.id
#   rule_number    = 1
#   egress         = true
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.default.cidr_block
#   from_port      = 0
#   to_port        = 0
# }

resource "aws_network_acl_rule" "out_transit_world" {
  count          = var.transit_subnet ? 1 : 0
  network_acl_id = aws_network_acl.transit[0].id
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

resource "aws_network_acl_rule" "in_transit_local" {
  count          = var.transit_subnet ? 1 : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = 1
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_vpc.default.cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "in_transit_tcp" {
  count          = var.transit_subnet ? length(var.transit_nacl_inbound_tcp_ports) : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = count.index + 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.transit_nacl_inbound_tcp_ports[count.index]
  to_port        = var.transit_nacl_inbound_tcp_ports[count.index]
}

resource "aws_network_acl_rule" "in_transit_tcp_return" {
  count          = var.transit_subnet ? 1 : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = 201
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_transit_udp" {
  count          = var.transit_subnet ? length(var.transit_nacl_inbound_udp_ports) : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = count.index + 301
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.transit_nacl_inbound_udp_ports[count.index]
  to_port        = var.transit_nacl_inbound_udp_ports[count.index]
}

resource "aws_network_acl_rule" "in_transit_udp_return" {
  count          = var.transit_subnet ? 1 : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = 401
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_transit_icmp" {
  count          = var.transit_subnet ? 1 : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = 501
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 0
  icmp_code      = -1
}

resource "aws_network_acl_rule" "in_transit_from_private" {
  count          = var.transit_subnet ? var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.private[*].cidr_block) : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = count.index + 601
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.private_subnet_summary : aws_subnet.private[count.index].cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "in_transit_from_secure" {
  count          = var.transit_subnet ? var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.secure[*].cidr_block) : 0
  network_acl_id = aws_network_acl.transit[0].id
  rule_number    = count.index + 701
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.secure_subnet_summary : aws_subnet.secure[count.index].cidr_block
  from_port      = 0
  to_port        = 0
}


#############
# S3 Endpoint
#############
resource "aws_network_acl_rule" "in_private_from_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 801
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "out_private_to_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 801
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}

#############
# Dynamodb Endpoint
#############
resource "aws_network_acl_rule" "in_private_from_dynamodb" {
  count          = var.vpc_endpoint_dynamodb_gateway ? length(data.aws_ec2_managed_prefix_list.dynamodb.entries) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 901
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.dynamodb.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "out_private_to_dynamodb" {
  count          = var.vpc_endpoint_dynamodb_gateway ? length(data.aws_ec2_managed_prefix_list.dynamodb.entries) : 0
  network_acl_id = aws_network_acl.private.id
  rule_number    = count.index + 901
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.dynamodb.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}
