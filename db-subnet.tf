resource "aws_db_subnet_group" "secure" {
  name       = "${lower(var.name)}-dbsubnet"
  subnet_ids = aws_subnet.secure.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-DBSubnet"
      "Scheme"  = "secure"
      "EnvName" = var.name
    },
  )
}
