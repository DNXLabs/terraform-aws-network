resource "aws_network_acl" "secure" {
  vpc_id     = "${aws_vpc.default.id}"
  subnet_ids = ["${aws_subnet.secure.*.id}"]

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

###########
# INGRESS
###########

resource "aws_network_acl_rule" "in_secure_from_private_tcp" {
  count          = "${length(var.secure_nacl_inbound_tcp_ports)*length(aws_subnet.private.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 101}"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.*.cidr_block[count.index%length(aws_subnet.private.*.cidr_block)]}"

  # the mess below is just to allow the list to be empty without getting a "divide by zero" error
  from_port = "${element(coalescelist(var.secure_nacl_inbound_tcp_ports, list("0")), count.index%(length(var.secure_nacl_inbound_tcp_ports)==0 ? 1 : length(var.secure_nacl_inbound_tcp_ports)))}"
  to_port   = "${element(coalescelist(var.secure_nacl_inbound_tcp_ports, list("0")), count.index%(length(var.secure_nacl_inbound_tcp_ports)==0 ? 1 : length(var.secure_nacl_inbound_tcp_ports)))}"
}

resource "aws_network_acl_rule" "in_secure_from_private_udp" {
  count          = "${length(var.secure_nacl_inbound_udp_ports)*length(aws_subnet.private.*.cidr_block)}"
  network_acl_id = "${aws_network_acl.secure.id}"
  rule_number    = "${count.index + 201}"
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.*.cidr_block[count.index%length(aws_subnet.private.*.cidr_block)]}"

  # the mess below is just to allow the list to be empty without getting a "divide by zero" error
  from_port = "${element(coalescelist(var.secure_nacl_inbound_udp_ports, list("0")), count.index%(length(var.secure_nacl_inbound_udp_ports)==0 ? 1 : length(var.secure_nacl_inbound_udp_ports)))}"
  to_port   = "${element(coalescelist(var.secure_nacl_inbound_udp_ports, list("0")), count.index%(length(var.secure_nacl_inbound_udp_ports)==0 ? 1 : length(var.secure_nacl_inbound_udp_ports)))}"
}
