resource "aws_eip" "nat_eip" {
  count = "${var.nat_count}"
  vpc   = true
}

resource "aws_nat_gateway" "nat_gw" {
  count         = "${var.nat_count}"
  allocation_id = "${aws_eip.nat_eip.*.id[count.index]}"
  subnet_id     = "${aws_subnet.public.*.id[count.index]}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["subnet_id"]
  }

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-NATGW",
      "EnvName", "${var.name}"
    )
  )}"
}
