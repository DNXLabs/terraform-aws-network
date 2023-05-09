resource "aws_vpc_endpoint" "dynamodb" {
  count        = var.vpc_endpoint_dynamodb_gateway ? 1 : 0
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  policy = <<POLICY
    {
        "Statement": [
            {
                "Action": "*","Effect": "Allow","Resource": "*","Principal": "*"
            }
        ]
    }
    POLICY

  lifecycle {
    ignore_changes = [policy]
  }

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].endpoint_dynamodb, var.name, local.name_suffix)
      "EnvName" = var.name
    },
  )

  depends_on = [aws_vpc.default]
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb" {
  count           = var.vpc_endpoint_dynamodb_gateway ? length(aws_subnet.private) : 0
  route_table_id  = var.multi_nat ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
}