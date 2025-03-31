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
  for_each = var.vpc_endpoint_s3_gateway ? {
    for idx, subnet in aws_subnet.private : idx => subnet
  } : {}

  route_table_id  = var.multi_nat || var.multi_az_private_rtb ? aws_route_table.private[each.key].id : aws_route_table.private[0].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}
