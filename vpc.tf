resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-VPC",
      "EnvName", "${var.name}"
    )
  )}"
}

resource "aws_vpc_ipv4_cidr_block_association" "transit" {
  count      = "${var.transit_subnet ? 1 : 0}"
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "${var.vpc_cidr_transit}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-IG",
      "EnvName", "${var.name}"
    )
  )}"
}
