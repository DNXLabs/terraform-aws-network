resource "aws_cloudformation_stack" "tf_exports" {
  name = "terraform-exports-network-${var.name}"
  template_body = templatefile("${path.module}/cf-exports.yml", {
    "name" = var.cf_export_name != "" ? var.cf_export_name : var.name
    "vars" = {
      "VpcId"              = aws_vpc.default.id,
      "CidrBlock"          = aws_vpc.default.cidr_block,
      "InternetGatewayId"  = aws_internet_gateway.default.id,
      "PublicSubnetIds"    = join(",", aws_subnet.public[*].id),
      "PublicSubnetCidrs"  = join(",", aws_subnet.public[*].cidr_block),
      "PrivateSubnetIds"   = join(",", aws_subnet.private[*].id),
      "PrivateSubnetCidrs" = join(",", aws_subnet.private[*].cidr_block),
      "SecureSubnetIds"    = join(",", aws_subnet.secure[*].id),
      "SecureSubnetCidrs"  = join(",", aws_subnet.secure[*].cidr_block),
      "NatGatewayIds"      = var.nat ? join(",", aws_nat_gateway.nat_gw[*].id) : "undefined",
      "DbSubnetGroupId"    = aws_db_subnet_group.secure.id
    }
  })
}
