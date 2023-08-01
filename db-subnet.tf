resource "aws_db_subnet_group" "secure" {
  name       = lower(format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix))
  subnet_ids = aws_subnet.secure[*].id

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix)
      "Scheme"  = "secure"
      "EnvName" = var.name
    },
  )
}
