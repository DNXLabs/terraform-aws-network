resource "aws_vpc_endpoint" "default" {
  count = length(var.vpc_endpoints)

  vpc_id              = aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${var.vpc_endpoints[count.index]}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = var.vpc_endpoints[count.index] == "s3" ? false : true
  subnet_ids          = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints[count.index].id,
  ]

  lifecycle {
    ignore_changes = [policy]
  }

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-${var.vpc_endpoints[count.index]}-Endpoint"
      "EnvName" = var.name
    },
  )

  depends_on = [aws_vpc.default]

}

resource "aws_security_group" "vpc_endpoints" {
  count = length(var.vpc_endpoints)

  name   = "${var.vpc_endpoints[count.index]}-vpc-endpoint-sg"
  vpc_id = aws_vpc.default.id

  ingress {
    description = "Allow traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.vpc_endpoints[count.index]}-vpc-endpoint-sg"
  }
}
