resource "aws_eip" "nat_eip" {
  count = var.nat && var.multi_nat ? (
    length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  ) : (var.nat ? 1 : 0)
  vpc   = true

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-EIP-${count.index}"
      "EnvName" = var.name
    },
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count = var.nat && var.multi_nat ? (
    length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)
  ) : (var.nat ? 1 : 0)

  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-NATGW-${count.index}"
      "EnvName" = var.name
    },
  )
}
