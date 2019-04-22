resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-VPC",
      "TerraformWorkspace", "${terraform.workspace}",
      "EnvName", "${var.name}"
    )
  )}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(
    var.tags,
    map(
      "Name", "${var.name}-IG",
      "EnvName", "${var.name}"
    )
  )}"
}
