resource "aws_network_interface" "nat_instance" {
  count = var.nat_instance ? var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1 : 0

  security_groups   = [aws_security_group.nat_instance[0].id]
  subnet_id         = aws_subnet.public[count.index].id
  source_dest_check = false
  description       = "ENI for NAT instance ${count.index}"
  tags  = {
    Name = "nat-instance-${count.index}"
    Function = "NAT-instance"
  }
}

resource "aws_eip" "nat_instance" {
  count = var.nat_instance ? var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1 : 0
  network_interface = var.multi_nat ? aws_network_interface.nat_instance[count.index].id : null
  tags  = {
    Name = "EIPforNAT_Instance-${count.index}"
    Function = "NAT-instance"
  }
}

resource "aws_route" "nat_instance" {
  count                  = var.nat_instance ? length(aws_route_table.private[*].id) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat_instance[count.index].id

  lifecycle {
    ignore_changes        = [network_interface_id]
  }
}

data "template_file" "userdata" {
  template = "${file("${path.module}/data/init.sh")}"
}

resource "aws_launch_template" "template_linux" {
  count       = var.nat_instance ? 1 : 0
  name        = "lt-nat_instance"
  image_id    = data.aws_ami.amazon_linux.id

  iam_instance_profile {
    arn = aws_iam_instance_profile.nat_instance[0].arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.nat_instance[0].id]
    delete_on_termination       = true
  }
  
  user_data = base64encode(data.template_file.userdata.rendered)

  description = "Launch template for NAT instance ${var.name}"
  tags = {
    Name = "nat-instance-${var.name}"
  }
}

resource "aws_autoscaling_group" "nat_instance" {
#   count               = var.nat_instance ? var.multi_nat ? length(data.aws_availability_zones.available.names) : 1 : var.max_az : 1 : 0
  count = var.nat_instance ? var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1 : 0
  name                = "nat_instance-${count.index}"
  capacity_rebalance  = true
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = var.multi_nat ? [aws_subnet.public[count.index].id] : aws_subnet.public[*].id
  

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = var.multi_nat ? "lowest-price" : "capacity-optimized"
      spot_instance_pools                      = var.multi_nat ? 10 : 0
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.template_linux[0].id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }

  tag {
    key                 = "Name"
    value               = "nat-instance-${var.name}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "nat_instance" {
  count = var.nat_instance ? 1 : 0
  name  = "profile_nat_instance"
  role  = aws_iam_role.nat_instance[0].name
}

resource "aws_iam_role" "nat_instance" {
  count = var.nat_instance ? 1 : 0
  name        = "nat_instance"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "nat_instance" {
  count = var.nat_instance ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nat_instance[0].name
}

resource "aws_iam_role_policy" "nat_instance" {
  count = var.nat_instance ? 1 : 0
  role        = aws_iam_role.nat_instance[0].name
  name        = "nat_instance"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:ReplaceRoute",
                "ec2:CreateRoute"
            ],
            "Resource": "arn:aws:ec2:*:*:route-table/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeRouteTables",
                "ec2:DescribeAddresses",
                "ec2:AttachNetworkInterface",
                "ec2:ModifyInstanceAttribute",
                "ec2:AssociateAddress"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_security_group" "nat_instance" {
  count = var.nat_instance ? 1 : 0
  name_prefix = var.name
  vpc_id      = aws_vpc.default.id
  description = "Security group for NAT instance ${var.name}"
  tags  = {
    Name = "nat-instance"
  }
}

resource "aws_security_group_rule" "egress" {
  count = var.nat_instance ? 1 : 0
  security_group_id = aws_security_group.nat_instance[0].id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ingress" {
#   count             = var.nat_instance ? var.multi_nat ? length(aws_subnet.private.*.cidr_block) : 1 : 0
  count = var.nat_instance ? var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1 : 0
  description       = "Allow traffic from Subnet Private"
  security_group_id = aws_security_group.nat_instance[0].id
  type              = "ingress"
  cidr_blocks       = var.multi_nat ? [aws_subnet.private[count.index].cidr_block] : aws_subnet.private[*].cidr_block
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}
