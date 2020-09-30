resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  policy = <<POLICY
    {
        "Statement": [
            {
                "Action": "*","Effect": "Allow","Resource": "*","Principal": "*"
            }
        ]
    }
    POLICY

  lifecycle {
    ignore_changes = [policy]
  }

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-S3-Endpoint"
      "EnvName" = var.name
    },
  )

  depends_on = [aws_vpc.default]

}