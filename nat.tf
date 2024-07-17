locals {
  nat_quantity = var.nat ? var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1 : 0
}

resource "aws_eip" "nat_eip" {
  count  = var.byoip ? 0 : local.nat_quantity
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].eip, var.name, count.index, local.name_suffix)
      "EnvName" = var.name
    },
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count         = local.nat_quantity
  allocation_id = var.byoip ? var.eip_allocation_ids[count.index] : aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].natgw, var.name, count.index, local.name_suffix)
      "EnvName" = var.name
    },
  )
}
