resource "aws_eip" "nat_eip" {
  # count = var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : var.nat_gw ? 1 : 0
  count = var.nat_gw ? var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1 : 0
  vpc   = true

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-EIP-${count.index}"
      "EnvName" = var.name
      "Az"      = upper(data.aws_availability_zone.az[count.index].name_suffix)
    },
  )
}

resource "aws_nat_gateway" "nat_gw" {
  # count         = var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : var.nat_gw ? 1 : 0
  count         = var.nat_gw ? var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1 : 0
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-NATGW-${count.index}"
      "EnvName" = var.name
      "Az"      = upper(data.aws_availability_zone.az[count.index].name_suffix)
    },
  )
}
