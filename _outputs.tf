output "vpc_id" {
  value       = aws_vpc.default.id
  description = "ID for VPC created"
}

output "cidr_block" {
  value       = aws_vpc.default.cidr_block
  description = "CIDR for VPC created"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.default.id
  description = "ID of Internet Gateway created"
}

output "public_subnet_ids" {
  value       = [aws_subnet.public.*.id]
  description = "List of public subnet IDs"
}

output "public_subnet_cidrs" {
  value       = [aws_subnet.public.*.cidr_block]
  description = "List of public subnet CIDRs"
}

output "private_subnet_ids" {
  value       = [aws_subnet.private.*.id]
  description = "List of private subnet IDs"
}

output "private_subnet_cidrs" {
  value       = [aws_subnet.private.*.cidr_block]
  description = "List of private subnet CIDRs"
}

output "secure_subnet_ids" {
  value       = [aws_subnet.secure.*.id]
  description = "List of secure subnet IDs"
}

output "secure_subnet_cidrs" {
  value       = [aws_subnet.secure.*.cidr_block]
  description = "List of secure subnet CIDRs"
}

output "nat_gateway_ids" {
  value       = [aws_nat_gateway.nat_gw.*.id]
  description = "List of NAT Gateway IDs"
}

output "db_subnet_group_id" {
  value = aws_db_subnet_group.secure.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = [aws_route_table.private.*.id]
}

output "secure_route_table_id" {
  value = aws_route_table.secure.id
}

output "transit_route_table_id" {
  value = [aws_route_table.transit.*.id]
}
