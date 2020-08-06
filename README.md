# terraform-aws-network

[![Lint Status](https://github.com/DNXLabs/terraform-aws-network/workflows/Lint/badge.svg)](https://github.com/DNXLabs/terraform-aws-network/actions)
[![LICENSE](https://img.shields.io/github/license/DNXLabs/terraform-aws-network)](https://github.com/DNXLabs/terraform-aws-network/blob/master/LICENSE)

This terraform module basic network resources for a region - NEW VERSION.

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.20 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cf\_export\_name | Name prefix for the export resources of the cloud formation output | `string` | `""` | no |
| max\_az | Max number of AZs | `number` | `3` | no |
| multi\_nat | Number of NAT Instances, 'true' will yield one per AZ while 'false' creates one NAT | `bool` | `false` | no |
| name | Name prefix for the resources of this stack | `any` | n/a | yes |
| newbits | Number of bits to add to the vpc cidr when building subnets | `number` | `5` | no |
| private\_netnum\_offset | Start with this subnet for private ones, plus number of AZs | `number` | `5` | no |
| public\_nacl\_inbound\_tcp\_ports | TCP Ports to allow inbound on public subnet via NACLs (this list cannot be empty) | `list(string)` | <pre>[<br>  "80",<br>  "443",<br>  "22",<br>  "1194"<br>]</pre> | no |
| public\_nacl\_inbound\_udp\_ports | UDP Ports to allow inbound on public subnet via NACLs (this list cannot be empty) | `list(string)` | `[]` | no |
| public\_netnum\_offset | Start with this subnet for public ones, plus number of AZs | `number` | `0` | no |
| secure\_netnum\_offset | Start with this subnet for secure ones, plus number of AZs | `number` | `10` | no |
| tags | Extra tags to attach to resources | `map(string)` | `{}` | no |
| transit\_nacl\_inbound\_tcp\_ports | TCP Ports to allow inbound on transit subnet via NACLs (this list cannot be empty) | `list(string)` | <pre>[<br>  "1194"<br>]</pre> | no |
| transit\_nacl\_inbound\_udp\_ports | UDP Ports to allow inbound on transit subnet via NACLs (this list cannot be empty) | `list(string)` | <pre>[<br>  "1194"<br>]</pre> | no |
| transit\_netnum\_offset | Start with this subnet for secure ones, plus number of AZs | `number` | `15` | no |
| transit\_subnet | Create a transit subnet for VPC peering (only central account) | `bool` | `false` | no |
| vpc\_cidr | Network CIDR for the VPC | `any` | n/a | yes |
| vpc\_cidr\_transit | Network CIDR for Transit subnets | `string` | `"10.255.255.0/24"` | no |
| vpc\_flow\_logs\_retention | Retention in days for VPC Flow Logs CloudWatch Log Group | `number` | `365` | no |

## Outputs

| Name | Description |
|------|-------------|
| cidr\_block | CIDR for VPC created |
| db\_subnet\_group\_id | n/a |
| internet\_gateway\_id | ID of Internet Gateway created |
| nat\_gateway\_ids | List of NAT Gateway IDs |
| private\_subnet\_cidrs | List of private subnet CIDRs |
| private\_subnet\_ids | List of private subnet IDs |
| public\_subnet\_cidrs | List of public subnet CIDRs |
| public\_subnet\_ids | List of public subnet IDs |
| secure\_subnet\_cidrs | List of secure subnet CIDRs |
| secure\_subnet\_ids | List of secure subnet IDs |
| vpc\_id | ID for VPC created |

<!--- END_TF_DOCS --->

## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-aws-network/blob/master/LICENSE) for full details.
