resource "aws_subnet" "public" {
  count  = length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.default.id
  cidr_block = cidrsubnet(
    aws_vpc.default.cidr_block,
    var.newbits,
    count.index + var.public_netnum_offset,
  )
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-Subnet-Public-${upper(data.aws_availability_zone.az[count.index].name_suffix)}"
      "Scheme"  = "public"
      "EnvName" = var.name
    },
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-RouteTable-Public"
      "Scheme"  = "public"
      "EnvName" = var.name
    },
  )
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

  lifecycle {
    # ignore_changes        = ["subnet_id", "route_table_id"]
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint_route_table_association" "public" {
  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}