resource "aws_subnet" "secure" {
  count  = length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.default.id
  cidr_block = cidrsubnet(
    aws_vpc.default.cidr_block,
    var.newbits,
    count.index + var.secure_netnum_offset,
  )
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-Subnet-Secure-${upper(data.aws_availability_zone.az[count.index].name_suffix)}"
      "Scheme"  = "secure"
      "EnvName" = var.name
      "Az"      = "${upper(data.aws_availability_zone.az[count.index].name_suffix)}"
    },
  )
  lifecycle {
    ignore_changes        = [tags]
  }
  depends_on = [aws_nat_gateway.nat_gw]
}

resource "aws_route_table" "secure" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-RouteTable-Secure"
      "Scheme"  = "secure"
      "EnvName" = var.name
    },
  )
}

resource "aws_route_table_association" "secure" {
  count          = length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.secure[count.index].id
  route_table_id = aws_route_table.secure.id

  lifecycle {
    ignore_changes        = [subnet_id]
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint_route_table_association" "secure" {
  route_table_id  = aws_route_table.secure.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}