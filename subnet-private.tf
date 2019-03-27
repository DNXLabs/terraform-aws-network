resource "aws_subnet" "private" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.default.cidr_block, var.newbits, count.index + var.private_netnum_offset)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false
  tags                    = "${merge(map("Name", "${var.name}-Subnet-Private-${upper(data.aws_availability_zone.az.*.name_suffix[count.index])}"), map("Scheme", "private"), var.tags)}"
  depends_on              = ["aws_nat_gateway.nat_gw"]
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.default.id}"
  tags   = "${merge(map("Name", "${var.name}-RouteTable-Private"), var.tags)}"
}

resource "aws_route" "nat_route" {
  route_table_id = "${aws_route_table.private.id}"

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat_gw.id}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["route_table_id", "nat_gateway_id"]
  }

  depends_on = ["aws_nat_gateway.nat_gw"]
}

resource "aws_route_table_association" "private" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.id}"

  lifecycle {
    ignore_changes        = ["subnet_id"]
    create_before_destroy = true
  }
}
