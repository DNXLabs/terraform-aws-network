resource "aws_subnet" "firewall" {
  count  = var.network_firewall ? local.nat_quantity : 0
  vpc_id = aws_vpc.default.id

  cidr_block = cidrsubnet(
    aws_vpc.default.cidr_block,
    14,
    count.index + var.firewall_netnum_offset,
  )

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name"                = "${var.name}-Subnet-Firewall-${upper(data.aws_availability_zone.az[count.index].name_suffix)}"
      "Scheme"              = "firewall"
      "EnvName"             = var.name
    },
  )
}

resource "aws_route_table" "firewall" {
  count  = var.network_firewall ? local.nat_quantity : 0
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-RouteTable-Firewall-${count.index}"
      "Scheme"  = "firewall"
      "EnvName" = var.name
    },
  )
}

resource "aws_route" "firewall_route" {
  count                  = var.network_firewall ? local.nat_quantity : 0
  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id

  lifecycle {
    create_before_destroy = true
  }
}

# IGW route table
resource "aws_route_table" "igw_route_table" {
  count  = var.network_firewall ? 1 : 0
  vpc_id = aws_vpc.default.id
  tags   = merge(
    var.tags,
    {
      "Name"    = "${var.name}-RouteTable-IGW"
      "EnvName" = var.name
    },
  )
}

resource "aws_route_table_association" "edge_association" { 
  count          = var.network_firewall ? 1 : 0
  gateway_id     = aws_internet_gateway.default.id
  route_table_id = aws_route_table.igw_route_table[0].id
}

resource "aws_route" "igw_route" {
  count                  = var.network_firewall ? local.nat_quantity : 0
  route_table_id         = aws_route_table.igw_route_table[0].id
  destination_cidr_block = aws_subnet.public[count.index].cidr_block
  vpc_endpoint_id        = (aws_networkfirewall_firewall.default[0].firewall_status[0].sync_states[*].attachment[0].endpoint_id)[0]
}