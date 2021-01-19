data "aws_availability_zones" "available" {}

data "aws_availability_zone" "az" {
  count = length(data.aws_availability_zones.available.names)
  name  = data.aws_availability_zones.available.names[count.index]
}

data "aws_region" "current" {}

# data "aws_vpc" "selected" {
#   filter {
#     name   = "tag:Name"
#     values = ["${local.workspace["account_name"]}-VPC"]
#   }
# }

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.selected.id}"

  filter {
    name   = "tag:Scheme"
    values = ["public"]
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.selected.id}"

  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

data "aws_security_group" "selected" {
  vpc_id = "${data.aws_vpc.selected.id}"
  filter {
    name   = "group-name"
    values = ["default"]
  }
}


data "aws_route_tables" "routes_private" {
  vpc_id = "${data.aws_vpc.selected.id}"

  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
}