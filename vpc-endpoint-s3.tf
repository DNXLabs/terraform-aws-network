resource "aws_vpc_endpoint" "s3" {
  count        = var.vpc_endpoint_s3_gateway ? 1 : 0
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  policy = var.vpc_endpoint_s3_policy

  lifecycle {
    ignore_changes = [policy]
  }

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].endpoint_s3, var.name, local.name_suffix)
      "EnvName" = var.name
    },
  )

  depends_on = [aws_vpc.default]
}

resource "aws_vpc_endpoint_route_table_association" "private" {
  count           = var.vpc_endpoint_s3_gateway ? length(aws_subnet.private) : 0
  route_table_id  = var.multi_nat ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}