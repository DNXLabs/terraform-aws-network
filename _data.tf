data "aws_availability_zones" "available" {
  state = "available"
}

output "aws_availability_zones" {
  value       = data.aws_availability_zones.available.names
  description = "aws_availability_zones"
}

data "aws_availability_zone" "az" {
  count = length(data.aws_availability_zones.available.names)
  name  = data.aws_availability_zones.available.names[count.index]
}

data "aws_region" "current" {}

# AMI of the latest Amazon Linux 2 
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
}
