resource "aws_subnet" "private" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.default.cidr_block, var.newbits, count.index + var.private_netnum_offset)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-Subnet-Private-${upper(data.aws_availability_zone.az.*.name_suffix[count.index])}",
      "Scheme", "private",
      "EnvName", "${var.name}"
    )
  )}"

  depends_on = ["aws_nat_gateway.nat_gw"]
}

resource "aws_route_table" "private" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-RouteTable-Private-${count.index}",
      "Scheme", "private",
      "EnvName", "${var.name}"
    )
  )}"
}

resource "aws_route" "nat_route" {
  count = "${var.multi_nat ? length(data.aws_availability_zones.available.names) : 0}"

  route_table_id         = "${aws_route_table.private.*.id[count.index]}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat_gw.*.id[count.index]}"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_nat_gateway.nat_gw"]
}

resource "aws_route" "nat_route_single_nat" {
  count = "${var.multi_nat ? 0 : length(data.aws_availability_zones.available.names)}"

  route_table_id         = "${aws_route_table.private.*.id[count.index]}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat_gw.*.id[0]}"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_nat_gateway.nat_gw"]
}

resource "aws_route_table_association" "private" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"

  lifecycle {
    ignore_changes        = ["subnet_id"]
    create_before_destroy = true
  }
}

# resource "aws_route_table_association" "private_single" {
#   count          = "${var.nat_count == length(data.aws_availability_zones.available.names) ? 0 : 1}"
#   subnet_id      = "${aws_subnet.private.*.id[count.index]}"
#   route_table_id = "${aws_route_table.private.*.id[count.index]}"


#   lifecycle {
#     ignore_changes        = ["subnet_id"]
#     create_before_destroy = true
#   }
# }

