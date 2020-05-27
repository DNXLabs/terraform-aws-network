# terraform-aws-network

[![Lint Status](https://github.com/DNXLabs/terraform-aws-network/workflows/Lint/badge.svg)](https://github.com/DNXLabs/terraform-aws-network/actions)
[![LICENSE](https://img.shields.io/github/license/DNXLabs/terraform-aws-network)](https://github.com/DNXLabs/terraform-aws-network/blob/master/LICENSE)

This terraform module basic network resources for a region.

## Usage

```hcl
module "network" {
  source = "git::https://github.com/DNXLabs/terraform-aws-network.git?ref=0.0.3"

  vpc_cidr              = "10.1.0.0/16"
  newbits               = 8             # will create /24 subnets
  name                  = "MyVPC"
  multi_nat             = false
}
```

<!--- BEGIN_TF_DOCS --->
<!--- END_TF_DOCS --->

## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-aws-network/blob/master/LICENSE) for full details.
