resource "aws_subnet" "transit" {
  count                   = "${var.transit_subnet ? length(data.aws_availability_zones.available.names) : 0}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr_transit, 2, count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-Subnet-Transit-${upper(data.aws_availability_zone.az.*.name_suffix[count.index])}",
      "Scheme", "transit",
      "EnvName", "${var.name}"
    )
  )}"

  depends_on = ["aws_vpc_ipv4_cidr_block_association.transit"]
}

resource "aws_route_table" "transit" {
  count  = "${var.transit_subnet ? 1 : 0}"
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-RouteTable-transit",
      "Scheme", "transit",
      "EnvName", "${var.name}"
    )
  )}"
}

resource "aws_route" "transit_internet_route" {
  count = "${var.transit_subnet ? 1 : 0}"

  route_table_id         = "${aws_route_table.transit.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "transit" {
  count = "${var.transit_subnet ? 1 : 0}"

  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.transit.*.id[count.index]}"
  route_table_id = "${aws_route_table.transit.id}"

  lifecycle {
    # ignore_changes        = ["subnet_id", "route_table_id"]
    create_before_destroy = true
  }
}
