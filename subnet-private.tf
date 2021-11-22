resource "aws_subnet" "private" {
  count  = length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.default.id

  cidr_block = cidrsubnet(
    aws_vpc.default.cidr_block,
    var.newbits,
    count.index + var.private_netnum_offset,
  )

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name"                = "${var.name}-Subnet-Private-${upper(data.aws_availability_zone.az[count.index].name_suffix)}"
      "Scheme"              = "private"
      "EnvName"             = var.name
      "aws-cdk:subnet-name" = "Private"
      "aws-cdk:subnet-type" = "Private"
    },
    local.kubernetes_clusters,
    length(var.kubernetes_clusters) != 0 ? { "kubernetes.io/role/internal-elb" = 1 } : {}
  )
}

resource "aws_route_table" "private" {
  count  = var.nat && var.multi_nat ? (
    length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  ) : 1
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-RouteTable-Private-${count.index}"
      "Scheme"  = "private"
      "EnvName" = var.name
    },
  )
}

resource "aws_route" "nat_route" {
  count = var.nat && var.multi_nat ? (
    length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  ) : (var.nat ? 1 : 0)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_nat_gateway.nat_gw]
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.multi_nat ? aws_route_table.private[count.index].id : aws_route_table.private[0].id

  lifecycle {
    ignore_changes        = [subnet_id]
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint_route_table_association" "private" {
  count           = var.vpc_endpoint_s3_gateway ? length(aws_subnet.private) : 0
  route_table_id  = var.multi_nat ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

# resource "aws_route_table_association" "private_single" {
#   count          = var.nat_count == length(data.aws_availability_zones.available.names) ? 0 : 1
#   subnet_id      = aws_subnet.private.*.id[count.index]
#   route_table_id = aws_route_table.private.*.id[count.index]
#
#   lifecycle {
#     ignore_changes        = ["subnet_id"]
#     create_before_destroy = true
#   }
# }
