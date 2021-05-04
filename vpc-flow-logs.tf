resource "aws_flow_log" "vpc" {
  count           = var.vpc_flow_log ? 1 : 0
  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.default.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.vpc_flow_log ? 1 : 0
  name              = "/aws/vpc/${var.name}-VPC/flow-logs"
  retention_in_days = var.vpc_flow_logs_retention

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-VPC-Flow-LogGroup"
      "EnvName" = var.name
    },
  )
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.vpc_flow_log ? 1 : 0
  name  = "${var.name}-${data.aws_region.current.name}-VPC-flow-logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-VPC-Flow-IAM-Role"
      "EnvName" = var.name
      "Region"  = data.aws_region.current.name
    },
  )
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  count = var.vpc_flow_log ? 1 : 0
  name  = "${var.name}-${data.aws_region.current.name}-VPC-flow-logs"
  role  = aws_iam_role.vpc_flow_logs[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
