resource "aws_network_acl" "secure" {
  vpc_id     = "${aws_vpc.default.id}"
  subnet_ids = "${aws_subnet.secure.*.id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-ACL-Secure",
      "Scheme", "secure",
      "EnvName", "${var.name}"
    )
  )}"
}

###########
# EGRESS
###########

resource "aws_network_acl_rule" "out_secure_to_secure" {
  count          = "${length(aws_subnet.secure.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 1}"
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.secure.*.cidr_block[count.index]}"
}

resource "aws_network_acl_rule" "out_secure_to_private" {
  count          = "${length(aws_subnet.private.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 101}"
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.*.cidr_block[count.index]}"
}

resource "aws_network_acl_rule" "out_secure_to_transit" {
  count          = "${var.transit_subnet ? length(aws_subnet.transit.*.cidr_block) : 0}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 201}"
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.transit.*.cidr_block[count.index]}"
}

###########
# INGRESS
###########

resource "aws_network_acl_rule" "in_secure_from_secure" {
  count          = "${length(aws_subnet.secure.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 101}"
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.secure.*.cidr_block[count.index]}"
}

resource "aws_network_acl_rule" "in_secure_from_private" {
  count          = "${length(aws_subnet.private.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 201}"
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.*.cidr_block[count.index]}"
}

resource "aws_network_acl_rule" "in_secure_from_transit" {
  count          = "${var.transit_subnet ? length(aws_subnet.transit.*.cidr_block) : 0}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 301}"
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.transit.*.cidr_block[count.index]}"
}
