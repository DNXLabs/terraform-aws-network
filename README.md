# terraform-aws-network

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | Name prefix for the resources of this stack | string | n/a | yes |
| nat\_count | Number of NAT Gateways to create (usually 1 or the number of AZs) | string | `"1"` | no |
| newbits | Number of bits to add to the vpc cidr when building subnets | string | `"8"` | no |
| private\_netnum\_offset | Start with this subnet for private ones, plus number of AZs | string | `"10"` | no |
| public\_netnum\_offset | Start with this subnet for public ones, plus number of AZs | string | `"0"` | no |
| secure\_netnum\_offset | Start with this subnet for secure ones, plus number of AZs | string | `"20"` | no |
| tags | Extra tags to attach to resources | map | `<map>` | no |
| vpc\_cidr | Network CIDR for the VPC | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cidr\_block | CIDR for VPC created |
| internet\_gateway\_id | ID of Internet Gateway created |
| nat\_gateway\_ids | List of NAT Gateway IDs |
| private\_subnet\_cidrs | List of private subnet CIDRs |
| private\_subnet\_ids | List of private subnet IDs |
| public\_subnet\_cidrs | List of public subnet CIDRs |
| public\_subnet\_ids | List of public subnet IDs |
| secure\_subnet\_cidrs | List of secure subnet CIDRs |
| secure\_subnet\_ids | List of secure subnet IDs |
| vpc\_id | ID for VPC created |

## Authors

Module managed by [Allan Denot](https://github.com/adenot).

## License

Apache 2 Licensed. See LICENSE for full details.
