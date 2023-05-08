resource "aws_vpc_endpoint" "s3" {
  count        = var.vpc_endpoint_s3_gateway ? 1 : 0
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  policy = var.vpc_endpoint_s3_policy

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-S3-Endpoint"
      "EnvName" = var.name
    },
  )

  depends_on = [aws_vpc.default]
}