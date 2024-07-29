resource "aws_db_subnet_group" "secure" {
  count      = var.create_dbsubgroup_secure ? 1 : 0
  name       = lower("${format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix)}-secure")
  subnet_ids = aws_subnet.secure.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix)}-secure"
      "Scheme"  = "secure"
      "EnvName" = var.name
    },
  )
}

resource "aws_db_subnet_group" "private" {
  count      = var.create_dbsubgroup_private ? 1 : 0
  name       = lower("${format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix)}-private")
  subnet_ids = aws_subnet.private.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix)}-private"
      "Scheme"  = "private"
      "EnvName" = var.name
    },
  )
}

resource "aws_db_subnet_group" "public" {
  count      = var.create_dbsubgroup_public ? 1 : 0
  name       = lower("${format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix)}-public")
  subnet_ids = aws_subnet.public.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${format(local.names[var.name_pattern].db_subnet, var.name, local.name_suffix)}-public"
      "Scheme"  = "public"
      "EnvName" = var.name
    },
  )
}

