resource "aws_vpc_endpoint" "dynamodb" {
  count        = var.vpc_endpoint_dynamodb_gateway ? 1 : 0
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  policy = var.vpc_endpoint_dynamodb_policy

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-dynamodb-Endpoint"
      "EnvName" = var.name
    },
  )

  depends_on = [aws_vpc.default]

}