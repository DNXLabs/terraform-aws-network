locals {
  secure_subnet_ip      = split("/", element(aws_subnet.secure[*].cidr_block, length(aws_subnet.secure[*].cidr_block) - 1))[0]
  secure_subnet_summary = var.vpc_cidr_summ != "/0" ? "${cidrhost("${local.secure_subnet_ip}${var.vpc_cidr_summ}", 0)}${var.vpc_cidr_summ}" : aws_vpc.default.cidr_block
}
resource "aws_network_acl" "secure" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.secure[*].id

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].nacl_secure, var.name, local.name_suffix)
      "Scheme"  = "secure"
      "EnvName" = var.name
    }
  )
}

resource "aws_network_acl_rule" "in_secure_from_secure" {
  count          = var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.secure[*].cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 101
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.secure_subnet_summary : aws_subnet.secure[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_secure_to_secure" {
  count          = var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.secure[*].cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 1
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.secure_subnet_summary : aws_subnet.secure[count.index].cidr_block
}

resource "aws_network_acl_rule" "in_secure_from_private" {
  count          = var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.private[*].cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 201
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.private_subnet_summary : aws_subnet.private[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_secure_to_private" {
  count          = var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.private[*].cidr_block)
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 101
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.private_subnet_summary : aws_subnet.private[count.index].cidr_block
}

resource "aws_network_acl_rule" "in_secure_from_transit" {
  count          = var.transit_subnet ? var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.transit[*].cidr_block) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 301
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.transit_subnet_summary : aws_subnet.transit[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_secure_to_transit" {
  count          = var.transit_subnet ? var.vpc_cidr_summ != "/0" ? 1 : length(aws_subnet.transit[*].cidr_block) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 201
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_summ != "/0" ? local.transit_subnet_summary : aws_subnet.transit[count.index].cidr_block
}

#############
# S3 Endpoint
#############
resource "aws_network_acl_rule" "in_secure_from_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 501
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "out_secure_to_s3" {
  count          = var.vpc_endpoint_s3_gateway ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 501
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
resource "aws_network_acl_rule" "in_secure_from_dynamodb" {
  count          = var.vpc_endpoint_dynamodb_gateway ? length(data.aws_ec2_managed_prefix_list.dynamodb.entries) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 601
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.dynamodb.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "out_secure_to_dynamodb" {
  count          = var.vpc_endpoint_dynamodb_gateway ? length(data.aws_ec2_managed_prefix_list.dynamodb.entries) : 0
  network_acl_id = aws_network_acl.secure.id
  rule_number    = count.index + 601
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.dynamodb.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}
