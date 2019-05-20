resource "aws_network_acl" "private" {
  vpc_id     = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-ACL-Private",
      "Scheme", "private",
      "EnvName", "${var.name}"
    )
  )}"
}

###########
# EGRESS
###########

resource "aws_network_acl_rule" "out_private_to_world" {
  count          = "${length(aws_subnet.private.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = "${count.index + 1}"
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# resource "aws_network_acl_rule" "out_private_to_private" {
#   count          = "${length(aws_subnet.private.*.cidr_block)}"
#   network_acl_id = "${aws_network_acl.private.id}"
#   rule_number    = "${count.index + 1}"
#   egress         = true
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = "${aws_subnet.private.*.cidr_block[count.index]}"
#   from_port      = 0
#   to_port        = 0
# }

# resource "aws_network_acl_rule" "out_private_to_public" {
#   count          = "${length(aws_subnet.public.*.cidr_block)}"
#   network_acl_id = "${aws_network_acl.private.id}"
#   rule_number    = "${count.index + 100}"
#   egress         = true
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = "${aws_subnet.public.*.cidr_block[count.index]}"
#   from_port      = 0
#   to_port        = 0
# }

# resource "aws_network_acl_rule" "out_private_to_secure" {
#   count          = "${length(aws_subnet.secure.*.cidr_block)}"
#   network_acl_id = "${aws_network_acl.private.id}"
#   rule_number    = "${count.index + 200}"
#   egress         = true
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = "${aws_subnet.secure.*.cidr_block[count.index]}"
#   from_port      = 0
#   to_port        = 0
# }

###########
# INGRESS
###########

resource "aws_network_acl_rule" "in_private_from_world_tcp" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = "1"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "in_private_from_world_icmp_reply" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = "100"
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 0
  icmp_code      = -1
}

resource "aws_network_acl_rule" "in_private_from_private" {
  count          = "${length(aws_subnet.private.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = "${count.index + 201}"
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.*.cidr_block[count.index]}"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "in_private_from_public" {
  count          = "${length(aws_subnet.public.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = "${count.index + 301}"
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.*.cidr_block[count.index]}"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "in_private_from_secure" {
  count          = "${length(aws_subnet.secure.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = "${count.index + 401}"
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.secure.*.cidr_block[count.index]}"
  from_port      = 0
  to_port        = 0
}
