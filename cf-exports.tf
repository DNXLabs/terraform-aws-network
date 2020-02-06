resource "aws_cloudformation_stack" "tf_exports" {
  name = "terraform-exports-network-${var.name}"

  template_body = templatefile("${path.module}/cf-exports.yml", {
    "name" = var.name,
    "vars" = {
      "VpcId"              = "${aws_vpc.default.id}",
      "CidrBlock"          = "${aws_vpc.default.cidr_block}",
      "InternetGatewayId"  = "${aws_internet_gateway.default.id}",
      "PublicSubnetIds"    = "${aws_subnet.public.*.id[0]}",
      "PublicSubnetCidrs"  = "${aws_subnet.public.*.cidr_block[0]}",
      "PrivateSubnetIds"   = "${aws_subnet.private.*.id[0]}",
      "PrivateSubnetCidrs" = "${aws_subnet.private.*.cidr_block[0]}",
      "SecureSubnetIds"    = "${aws_subnet.secure.*.id[0]}",
      "SecureSubnetCidrs"  = "${aws_subnet.secure.*.cidr_block[0]}",
      "NatGatewayIds"      = "${aws_nat_gateway.nat_gw.*.id[0]}",
      "DbSubnetGroupId"    = "${aws_db_subnet_group.secure.id}"
    }
  })
}