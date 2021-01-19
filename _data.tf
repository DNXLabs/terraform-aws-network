data "aws_availability_zones" "available" {}

data "aws_availability_zone" "az" {
  count = length(data.aws_availability_zones.available.names)
  name  = data.aws_availability_zones.available.names[count.index]
}

data "aws_region" "current" {}

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