resource "aws_vpc_endpoint" "default" {
  for_each = { for index, e in var.vpc_endpoints : e.name => e }

  vpc_id              = aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value.name}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = each.value.name == "s3" ? false : true
  subnet_ids          = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints[each.value.name].id,
  ]

  policy = try(each.value.policy, null)

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-${each.key}-Endpoint"
      "EnvName" = var.name
    },
  )

  depends_on = [aws_vpc.default]

}

resource "aws_security_group" "vpc_endpoints" {
  for_each = { for index, e in var.vpc_endpoints : e.name => e }

  name   = "${each.value.name}-vpc-endpoint-sg"
  vpc_id = aws_vpc.default.id

  ingress {
    description = "Allow traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${each.value.name}-vpc-endpoint-sg"
  }
}
