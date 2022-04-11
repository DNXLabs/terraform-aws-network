resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].vpc, var.name, local.name_suffix)
      "EnvName" = var.name
    },
    {
      for cluster_name in concat(var.kubernetes_clusters, var.kubernetes_clusters_secure) :
      format("kubernetes.io/cluster/%s", cluster_name) => var.kubernetes_clusters_type
    },
  )
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name"    = format(local.names[var.name_pattern].ig, var.name, local.name_suffix)
      "EnvName" = var.name
    }
  )
}
