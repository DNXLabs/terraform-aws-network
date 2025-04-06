locals {
  use_nat_instance = lower(var.nat_type) == "instance" ? true : false

  nat_instance_quantity = local.use_nat_instance ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 0

  # Create mapping of AZ to all the private route tables that should use a NAT instance in that AZ
  az_to_route_tables = local.use_nat_instance ? {
    for rt in aws_route_table.private :
    try(aws_subnet.private[index(aws_route_table.private[*].id, rt.id)].availability_zone, aws_subnet.private[0].availability_zone) => rt.id...
  } : {}
}

# Security group for NAT instances
resource "aws_security_group" "nat_instance" {
  count       = local.use_nat_instance ? 1 : 0
  name_prefix = "nat-instance-sg"
  vpc_id      = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-nat-instance-sg-${local.name_suffix}"
    },
  )
}

resource "aws_security_group_rule" "nat_instance_egress" {
  count             = local.use_nat_instance ? 1 : 0
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.nat_instance[0].id
}

resource "aws_security_group_rule" "nat_instance_ingress" {
  count             = local.use_nat_instance ? 1 : 0
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = [aws_vpc.default.cidr_block]
  security_group_id = aws_security_group.nat_instance[0].id
}

# Security group for Lambda functions
resource "aws_security_group" "nat_lambda" {
  count       = local.use_nat_instance ? 1 : 0
  name_prefix = "alternat-lambda-sg"
  vpc_id      = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-nat-lambda-sg${local.name_suffix}"
    },
  )
}

resource "aws_security_group_rule" "nat_lambda_egress" {
  count             = local.use_nat_instance ? 1 : 0
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat_lambda[0].id
}

# Get Amazon Linux 2023 AMI for NAT instances
data "aws_ami" "amazon_linux_2023" {
  count       = local.use_nat_instance ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EIPs for NAT instances
resource "aws_eip" "nat_instance_eip" {
  count  = local.use_nat_instance ? local.nat_instance_quantity : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-nat-instance-eip-${count.index}${local.name_suffix}"
    },
  )
}

# Create cloud-init config for NAT instances
data "cloudinit_config" "nat_instance_config" {
  count         = local.use_nat_instance ? 1 : 0
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
    #cloud-config
    repo_update: true
    repo_upgrade: all
    packages:
      - aws-cli
      - jq
      - iptables
    EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/usr/bin/env bash
    USERDATA_CONFIG_FILE="/etc/alternat.conf"
    echo eip_allocation_ids_csv=${join(",", aws_eip.nat_instance_eip[*].id)} >> "$USERDATA_CONFIG_FILE"
    echo route_table_ids_csv=${join(",", flatten(values(local.az_to_route_tables)))} >> "$USERDATA_CONFIG_FILE"
    EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/assets/scripts/alternat.sh")
  }
}

# IAM role for NAT instances
resource "aws_iam_role" "nat_instance" {
  count = local.use_nat_instance ? 1 : 0
  name  = "${var.name}-nat-instance-role${local.name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

# IAM policy for NAT instances
resource "aws_iam_policy" "nat_instance" {
  count       = local.use_nat_instance ? 1 : 0
  name        = "${var.name}-nat-instance-policy${local.name_suffix}"
  description = "IAM policy for NAT instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AssociateAddress",
          "ec2:ModifyInstanceAttribute",
          "ec2:ReplaceRoute",
          "ec2:CreateRoute"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "nat_instance" {
  count      = local.use_nat_instance ? 1 : 0
  role       = aws_iam_role.nat_instance[0].name
  policy_arn = aws_iam_policy.nat_instance[0].arn
}

resource "aws_iam_instance_profile" "nat_instance" {
  count = local.use_nat_instance ? 1 : 0
  name  = "${var.name}-nat-instance-profile${local.name_suffix}"
  role  = aws_iam_role.nat_instance[0].name
}

# Launch template for NAT instances
resource "aws_launch_template" "nat_instance" {
  count = local.nat_instance_quantity

  name_prefix   = "nat-instance-"
  instance_type = var.nat_instance_config.nat_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.nat_instance[0].arn
  }
  image_id = data.aws_ami.amazon_linux_2023[0].id

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.nat_instance[0].id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        "Name"             = "${var.name}-nat-instance${local.name_suffix}"
        "alterNATInstance" = "true"
      }
    )
  }

  user_data = data.cloudinit_config.nat_instance_config[0].rendered

  tags = var.tags
}

# Auto Scaling Group for NAT instances
resource "aws_autoscaling_group" "nat_instance" {
  count = local.nat_instance_quantity

  name_prefix           = "nat-instance-${var.name}-asg-${count.index}"
  max_size              = 1
  min_size              = 1
  max_instance_lifetime = var.nat_instance_config.max_instance_lifetime
  vpc_zone_identifier   = [aws_subnet.public[count.index].id]

  launch_template {
    id      = aws_launch_template.nat_instance[count.index].id
    version = "$Latest"
  }

  initial_lifecycle_hook {
    name                    = "NATInstanceTerminationLifeCycleHook"
    default_result          = "CONTINUE"
    heartbeat_timeout       = var.nat_instance_config.lifecycle_heartbeat_timeout
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
    notification_target_arn = aws_sns_topic.alternat_topic[0].arn
    role_arn                = aws_iam_role.alternat_lifecycle_hook[0].arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SNS Topic for ASG lifecycle events
resource "aws_sns_topic" "alternat_topic" {
  count = local.use_nat_instance ? 1 : 0
  name  = "${var.name}-alternat-lifecycle-events${local.name_suffix}"
  tags  = var.tags
}

# IAM Role for ASG lifecycle hooks
resource "aws_iam_role" "alternat_lifecycle_hook" {
  count = local.use_nat_instance ? 1 : 0
  name  = "${var.name}-alternat-lifecycle-hook-role${local.name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "alternat_lifecycle_hook" {
  count       = local.use_nat_instance ? 1 : 0
  name        = "${var.name}-alternat-lifecycle-hook-policy${local.name_suffix}"
  description = "Policy for ASG lifecycle hooks to publish to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = aws_sns_topic.alternat_topic[0].arn
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alternat_lifecycle_hook" {
  count      = local.use_nat_instance ? 1 : 0
  role       = aws_iam_role.alternat_lifecycle_hook[0].name
  policy_arn = aws_iam_policy.alternat_lifecycle_hook[0].arn
}

# IAM Role for Lambda functions
resource "aws_iam_role" "nat_lambda_role" {
  count = local.use_nat_instance ? 1 : 0
  name  = "${var.name}-nat-lambda-role${local.name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "nat_lambda_policy" {
  count       = local.use_nat_instance ? 1 : 0
  name        = "${var.name}-nat-lambda-policy${local.name_suffix}"
  description = "Policy for Lambda functions to manage NAT instance routes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "ec2:DescribeRouteTables",
          "ec2:DescribeNatGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:ReplaceRoute",
          "ec2:CreateRoute"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:CompleteLifecycleAction"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "nat_lambda_policy" {
  count      = local.use_nat_instance ? 1 : 0
  role       = aws_iam_role.nat_lambda_role[0].name
  policy_arn = aws_iam_policy.nat_lambda_policy[0].arn
}

# Create the ZIP file for Lambda function (if using Zip package type)
data "archive_file" "lambda_zip" {
  count       = local.use_nat_instance ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/assets/functions/replace-route"
  output_path = "${path.module}/assets/functions/lambda.zip"
}

# Cloudwatch event rule for connectivity testing
resource "aws_cloudwatch_event_rule" "connectivity_test" {
  count               = local.use_nat_instance ? 1 : 0
  name                = "${var.name}-nat-connectivity-test${local.name_suffix}"
  description         = "Periodically tests NAT instance connectivity"
  schedule_expression = "rate(1 minute)"

  tags = var.tags
}

# Lambda function for connectivity testing
resource "aws_lambda_function" "connectivity_tester" {
  count         = local.use_nat_instance ? length(aws_subnet.private) : 0
  function_name = "${var.name}-nat-connectivity-tester-${count.index}${local.name_suffix}"
  role          = aws_iam_role.nat_lambda_role[0].arn

  # Package type-specific configurations
  package_type = "Zip"

  # For Zip package type
  runtime  = "python3.12"
  handler  = "app.connectivity_test_handler"
  filename = data.archive_file.lambda_zip[0].output_path

  # General configuration
  memory_size = 256
  timeout     = 300

  environment {
    variables = {
      ROUTE_TABLE_IDS_CSV = join(",", aws_route_table.private[*].id)
      PUBLIC_SUBNET_ID    = aws_subnet.public[count.index].id
      CHECK_URLS          = "https://www.google.com"
      HAS_IPV6            = "false"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private[count.index].id]
    security_group_ids = [aws_security_group.nat_lambda[0].id]
  }

  tags = var.tags
}

# CloudWatch event target for connectivity testing
resource "aws_cloudwatch_event_target" "connectivity_test" {
  count     = local.use_nat_instance ? length(aws_subnet.private) : 0
  rule      = aws_cloudwatch_event_rule.connectivity_test[0].name
  target_id = "connectivity-tester-${count.index}"
  arn       = aws_lambda_function.connectivity_tester[count.index].arn
}

# Lambda permission for CloudWatch event rule
resource "aws_lambda_permission" "connectivity_test" {
  count         = local.use_nat_instance ? length(aws_subnet.private) : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connectivity_tester[count.index].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.connectivity_test[0].arn
}

# Lambda function for ASG lifecycle hook
resource "aws_lambda_function" "alternat_autoscaling_hook" {
  count         = local.use_nat_instance ? 1 : 0
  function_name = "${var.name}-nat-autoscaling-hook${local.name_suffix}"
  role          = aws_iam_role.nat_lambda_role[0].arn

  # Package type-specific configurations
  package_type = "Zip"

  # For Zip package type
  runtime  = "python3.12"
  handler  = "app.connectivity_test_handler"
  filename = data.archive_file.lambda_zip[0].output_path

  # General configuration
  memory_size = 256
  timeout     = 300

  environment {
    variables = zipmap(
      [for az in data.aws_availability_zones.available.names : upper(replace(az, "-", "_"))],
      [for az in data.aws_availability_zones.available.names : join(",", aws_route_table.private[*].id)]
    )
  }

  tags = merge({
    FunctionName = "alternat-autoscaling-lifecycle-hook",
  }, var.tags)
}

# Lambda permission for SNS topic
resource "aws_lambda_permission" "sns_to_lambda" {
  count         = local.use_nat_instance ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alternat_autoscaling_hook[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alternat_topic[0].arn
}

# SNS subscription for Lambda function
resource "aws_sns_topic_subscription" "lambda_subscription" {
  count     = local.use_nat_instance ? 1 : 0
  topic_arn = aws_sns_topic.alternat_topic[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alternat_autoscaling_hook[0].arn
}

resource "aws_cloudwatch_dashboard" "nat_dashboard" {
  count          = local.use_nat_instance ? 1 : 0
  dashboard_name = "nat-instance-${var.name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Header information
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = <<-EOT
          # NAT Gateway vs NAT Instance Dashboard

          This dashboard compares metrics between NAT Gateway and NAT Instance resources across availability zones.
          EOT
        }
      },

      # NAT Instance Status - EC2 Status Check
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            for asg in aws_autoscaling_group.nat_instance : ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", asg.name, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Instance Status Check Failures"
          stat   = "Maximum"
        }
      },

      # NAT Instance CPU Utilization by AZ
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            for asg in aws_autoscaling_group.nat_instance : ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", asg.name, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Instance CPU Utilization By AZ"
          stat   = "Average"
        }
      },

      # NAT Instance Network In by AZ
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            for asg in aws_autoscaling_group.nat_instance : ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", asg.name, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Instance NetworkIn By AZ"
          stat   = "Sum"
        }
      },

      # NAT Instance Network Out by AZ
      {
        type   = "metric"
        x      = 8
        y      = 8
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            for asg in aws_autoscaling_group.nat_instance : ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", asg.name, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Instance NetworkOut By AZ"
          stat   = "Sum"
        }
      },

      # NAT Gateway Bytes Processed by AZ
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/NATGateway", "BytesInFromDestination", "NatGatewayId", aws_nat_gateway.nat_gw[0].id, { "period" : 60 }],
            ["AWS/NATGateway", "BytesInFromDestination", "NatGatewayId", aws_nat_gateway.nat_gw[0].id, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Gateway Bytes Processed In/Out"
          stat   = "Sum"
        }
      },

      # NAT Gateway Packets Processed by AZ
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/NATGateway", "PacketsInFromDestination", "NatGatewayId", aws_nat_gateway.nat_gw[0].id, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Gateway Packets Processed"
          stat   = "Sum"
        }
      },

      # NAT Gateway Error Port Allocation
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/NATGateway", "ErrorPortAllocation", "NatGatewayId", aws_nat_gateway.nat_gw[0].id, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Gateway Port Allocation Errors"
          stat   = "Sum"
        }
      },

      # NAT Gateway Connection Established
      {
        type   = "metric"
        x      = 12
        y      = 20
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/NATGateway", "ActiveConnectionCount", "NatGatewayId", aws_nat_gateway.nat_gw[0].id, { "period" : 60 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Gateway Active Connections"
          stat   = "Average"
        }
      },

      # NAT Instance vs Gateway Traffic Comparison
      # {
      #   type   = "metric"
      #   x      = 0
      #   y      = 26
      #   width  = 24
      #   height = 6
      #   properties = {
      #     view    = "timeSeries"
      #     stacked = false
      #     metrics = concat(
      #       flatten([
      #         for asg in aws_autoscaling_group.nat_instance : [
      #           ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", asg.name, { "period" : 60, "label" : "NAT Instance Network Out" }]
      #         ]
      #       ]),
      #       [
      #         ["AWS/NATGateway", "BytesProcessedOut", "NatGatewayId", aws_nat_gateway.nat_gw[0].id, { "period" : 60, "label" : "NAT Gateway Bytes Out" }]
      #       ]
      #     )
      #     region = data.aws_region.current.name
      #     title  = "NAT Instance vs Gateway Outbound Traffic"
      #     stat   = "Sum"
      #   }
      # },

      # Custom NAT Instance Connectivity Check by AZ
      {
        type   = "metric"
        x      = 0
        y      = 32
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["NATInstance", "ConnectivityCheck", "Destination", "https://www.google.com", { "period" : 300 }],
            ["NATInstance", "ConnectivityCheck", "Destination", "https://aws.amazon.com", { "period" : 300 }],
            ["NATInstance", "ConnectivityCheck", "Destination", "https://api.ipify.org", { "period" : 300 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Instance Connectivity Checks"
          stat   = "Average"
          yAxis = {
            left = {
              min = 0
              max = 1
            }
          }
        }
      },

      # NAT Instance Custom Network Metrics
      {
        type   = "metric"
        x      = 12
        y      = 32
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["NATInstance", "NetworkBytesIn", { "period" : 300 }],
            ["NATInstance", "NetworkBytesOut", { "period" : 300 }]
          ]
          region = data.aws_region.current.name
          title  = "NAT Instance Custom Network Metrics"
          stat   = "Average"
        }
      },

      # NAT Instance Logs - User Data
      {
        type   = "log"
        x      = 0
        y      = 38
        width  = 12
        height = 6
        properties = {
          query  = "SOURCE '/ec2/nat-instance/user-data' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region = data.aws_region.current.name
          title  = "NAT Instance User Data Logs"
          view   = "table"
        }
      },
    ]
  })
}
