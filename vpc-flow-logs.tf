resource "aws_flow_log" "vpc" {
  iam_role_arn    = "${aws_iam_role.vpc_flow_logs.arn}"
  log_destination = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.default.id}"
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.name}-VPC/flow-logs"
  retention_in_days = "${var.vpc_flow_logs_retention}"
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.name}-VPC-flow-logs"

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
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "${var.name}-VPC-flow-logs"
  role = "${aws_iam_role.vpc_flow_logs.id}"

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
