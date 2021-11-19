# terraform-aws-network

[![Lint Status](https://github.com/DNXLabs/terraform-aws-network/workflows/Lint/badge.svg)](https://github.com/DNXLabs/terraform-aws-network/actions)
[![LICENSE](https://img.shields.io/github/license/DNXLabs/terraform-aws-network)](https://github.com/DNXLabs/terraform-aws-network/blob/master/LICENSE)

This module creates the basic network resources for a region.

The following resources will be created:
 - Virtual Private Cloud (VPC)
     - Enable DNS Hostname - A DNS hostname is a name that uniquely and absolutely names a computer; it's composed of a host name and a domain name. DNS servers resolve DNS hostnames to their corresponding IP addresses.
 - VPC Flow Logs
 - AWS Cloudwatch log groups
 - Subnets
     - Public
     - Private
     - Secure
     - Transit
 - Internet Gateway
 - Route tables for the Public, Private, Secure and Transit subnets
 - Associate all Route Tables created to the correct subnet
 - Nat Gateway
 - Network Access Control List (NACL) for all subnets
 - Database Subnet group - Provides an RDS DB subnet group resources
 - S3 VPC endpoint



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
| terraform | >= 0.12.0 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| byoip | Enable EC2 Bring your own IP (BYOIP) pool | `bool` | `false` | no |
| cf\_export\_name | Name prefix for the export resources of the cloud formation output | `string` | `""` | no |
| eip\_allocation\_id | User-specified primary or secondary private IP address to associate with the Elastic IP address | `string` | n/a | yes |
| kubernetes\_clusters | List of kubernetes cluster names to creates tags in public and private subnets of this VPC | `list(string)` | `[]` | no |
| kubernetes\_clusters\_secure | List of kubernetes cluster names to creates tags in secure subnets of this VPC | `list(string)` | `[]` | no |
| kubernetes\_clusters\_type | Use either 'owned' or 'shared' for kubernetes cluster tags | `string` | `"shared"` | no |
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
| vpc\_endpoint\_s3\_gateway | Enable or disable VPC Endpoint for S3 Gateway | `bool` | `true` | no |
| vpc\_endpoints | AWS services to create a VPC endpoint on private subnets for (e.g: ssm, ec2, ecr.dkr) | `list(string)` | `[]` | no |
| vpc\_flow\_logs | Enable or disable VPC Flow Logs | `bool` | `true` | no |
| vpc\_flow\_logs\_retention | Retention in days for VPC Flow Logs CloudWatch Log Group | `number` | `365` | no |

## Outputs

| Name | Description |
|------|-------------|
| cidr\_block | CIDR for VPC created |
| db\_subnet\_group\_id | n/a |
| internet\_gateway\_id | ID of Internet Gateway created |
| nat\_gateway\_ids | List of NAT Gateway IDs |
| private\_nacl\_id | n/a |
| private\_route\_table\_id | n/a |
| private\_subnet\_cidrs | List of private subnet CIDRs |
| private\_subnet\_ids | List of private subnet IDs |
| public\_nacl\_id | n/a |
| public\_route\_table\_id | n/a |
| public\_subnet\_cidrs | List of public subnet CIDRs |
| public\_subnet\_ids | List of public subnet IDs |
| secure\_nacl\_id | n/a |
| secure\_route\_table\_id | n/a |
| secure\_subnet\_cidrs | List of secure subnet CIDRs |
| secure\_subnet\_ids | List of secure subnet IDs |
| transit\_nacl\_id | n/a |
| transit\_route\_table\_id | n/a |
| vpc\_id | ID for VPC created |

<!--- END_TF_DOCS --->

## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-aws-network/blob/master/LICENSE) for full details.
