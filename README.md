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
| terraform | >= 1.3.0 |
| terraform | >= 0.14.0 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| attachInternetGateway | To attach or not the internet gateway within the public subnet. | `bool` | `true` | no |
| byoip | Enable module to use your own Elastic IPs (Bring Your Own IP) | `bool` | `false` | no |
| cf\_export\_name | Name prefix for the export resources of the cloud formation output | `string` | `""` | no |
| eip\_allocation\_ids | User-specified primary or secondary private IP address to associate with the Elastic IP address | `list(string)` | `[]` | no |
| enable\_firewall\_default\_rule | Enable or disable the default stateful rule. | `bool` | `true` | no |
| firewall\_custom\_rule\_arn | The stateful rule group arn created outside the module | `list(string)` | `[]` | no |
| firewall\_custom\_rules | The stateful rule group rules specifications in Suricata file format, with one rule per line | `list(string)` | `[]` | no |
| firewall\_domain\_list | List the domain names you want to take action on. | `list(any)` | <pre>[<br>  ".amazonaws.com",<br>  ".github.com"<br>]</pre> | no |
| firewall\_netnum\_offset | Start with this subnet for secure ones, plus number of AZs | `number` | `14` | no |
| kms\_key\_arn | The ARN of the KMS Key to use when encrypting log data. | `string` | `""` | no |
| kubernetes\_clusters | List of kubernetes cluster names to creates tags in public and private subnets of this VPC | `list(string)` | `[]` | no |
| kubernetes\_clusters\_secure | List of kubernetes cluster names to creates tags in secure subnets of this VPC | `list(string)` | `[]` | no |
| kubernetes\_clusters\_type | Use either 'owned' or 'shared' for kubernetes cluster tags | `string` | `"shared"` | no |
| max\_az | Max number of AZs | `number` | `3` | no |
| multi\_nat | Number of NAT Instances, 'true' will yield one per AZ while 'false' creates one NAT | `bool` | `false` | no |
| name | Name prefix for the resources of this stack | `any` | n/a | yes |
| name\_pattern | Name pattern to use for resources. Options: default, kebab | `string` | `"default"` | no |
| name\_suffix | Adds a name suffix to all resources created | `string` | `""` | no |
| nat | Deploy NAT instance(s) | `bool` | `true` | no |
| network\_firewall | Enable or disable VPC Network Firewall | `bool` | `false` | no |
| newbits | Number of bits to add to the vpc cidr when building subnets | `number` | `5` | no |
| private\_netnum\_offset | Start with this subnet for private ones, plus number of AZs | `number` | `5` | no |
| public\_nacl\_icmp | Allows ICMP traffic to and from the public subnet | `bool` | `true` | no |
| public\_nacl\_inbound\_tcp\_ports | TCP Ports to allow inbound on public subnet via NACLs (this list cannot be empty) | `list(string)` | <pre>[<br>  "80",<br>  "443",<br>  "22",<br>  "1194"<br>]</pre> | no |
| public\_nacl\_inbound\_udp\_ports | UDP Ports to allow inbound on public subnet via NACLs (this list cannot be empty) | `list(string)` | `[]` | no |
| public\_nacl\_outbound\_tcp\_ports | TCP Ports to allow outbound to external services (use [0] to allow all ports) | `list(string)` | <pre>[<br>  "0"<br>]</pre> | no |
| public\_nacl\_outbound\_udp\_ports | UDP Ports to allow outbound to external services (use [0] to allow all ports) | `list(string)` | <pre>[<br>  "0"<br>]</pre> | no |
| public\_netnum\_offset | Start with this subnet for public ones, plus number of AZs | `number` | `0` | no |
| secure\_netnum\_offset | Start with this subnet for secure ones, plus number of AZs | `number` | `10` | no |
| tags | Extra tags to attach to resources | `map(string)` | `{}` | no |
| transit\_nacl\_inbound\_tcp\_ports | TCP Ports to allow inbound on transit subnet via NACLs (this list cannot be empty) | `list(string)` | <pre>[<br>  "1194"<br>]</pre> | no |
| transit\_nacl\_inbound\_udp\_ports | UDP Ports to allow inbound on transit subnet via NACLs (this list cannot be empty) | `list(string)` | <pre>[<br>  "1194"<br>]</pre> | no |
| transit\_netnum\_offset | Start with this subnet for secure ones, plus number of AZs | `number` | `15` | no |
| transit\_subnet | Create a transit subnet for VPC peering (only central account) | `bool` | `false` | no |
| vpc\_cidr | Network CIDR for the VPC | `any` | n/a | yes |
| vpc\_cidr\_summ | Define cidr used to summarize subnets by tier | `string` | `"/0"` | no |
| vpc\_cidr\_transit | Network CIDR for Transit subnets | `string` | `"10.255.255.0/24"` | no |
| vpc\_endpoint\_dynamodb\_gateway | Enable or disable VPC Endpoint for DynamoDB (Gateway) | `bool` | `true` | no |
| vpc\_endpoint\_dynamodb\_policy | A policy to attach to the endpoint that controls access to the service | `string` | `"    {
        \"Statement\": [
            {
                \"Action\": \"*\",\"Effect\": \"Allow\",\"Resource\": \"*\",\"Principal\": \"*\"
            }
        ]
    }
"` | no |
| vpc\_endpoint\_s3\_gateway | Enable or disable VPC Endpoint for S3 Gateway | `bool` | `true` | no |
| vpc\_endpoint\_s3\_policy | A policy to attach to the endpoint that controls access to the service | `string` | `"    {
        \"Statement\": [
            {
                \"Action\": \"*\",\"Effect\": \"Allow\",\"Resource\": \"*\",\"Principal\": \"*\"
            }
        ]
    }
"` | no |
| vpc\_endpoints | AWS services to create a VPC endpoint on private subnets for (e.g: ssm, ec2, ecr.dkr) | <pre>list(object(<br>    {<br>      name          = string<br>      policy        = optional(string)<br>      allowed_cidrs = optional(list(string))<br>    }<br>  ))</pre> | `[]` | no |
| vpc\_flow\_logs | Enable or disable VPC Flow Logs | `bool` | `true` | no |
| vpc\_flow\_logs\_retention | Retention in days for VPC Flow Logs CloudWatch Log Group | `number` | `365` | no |

## Outputs

| Name | Description |
|------|-------------|
| cidr\_block | CIDR for VPC created |
| db\_subnet\_group\_id | n/a |
| firewall\_subnet\_cidrs | List of firewall subnet CIDRs |
| firewall\_subnet\_ids | List of firewall subnet IDs |
| internet\_gateway\_id | ID of Internet Gateway created |
| nat\_gateway | n/a |
| nat\_gateway\_ids | List of NAT Gateway IDs |
| private\_nacl\_id | n/a |
| private\_nacls | n/a |
| private\_route\_table\_id | n/a |
| private\_subnet\_cidrs | List of private subnet CIDRs |
| private\_subnet\_ids | List of private subnet IDs |
| private\_subnets | n/a |
| public\_nacl\_id | n/a |
| public\_nacls | n/a |
| public\_route\_table\_id | n/a |
| public\_subnet\_cidrs | List of public subnet CIDRs |
| public\_subnet\_ids | List of public subnet IDs |
| public\_subnets | n/a |
| secure\_db\_subnet | n/a |
| secure\_nacl\_id | n/a |
| secure\_nacls | n/a |
| secure\_route\_table\_id | n/a |
| secure\_subnet\_cidrs | List of secure subnet CIDRs |
| secure\_subnet\_ids | List of secure subnet IDs |
| secure\_subnets | n/a |
| transit\_nacl\_id | n/a |
| transit\_route\_table\_id | n/a |
| transit\_subnets | n/a |
| vpc\_id | ID for VPC created |

<!--- END_TF_DOCS --->

## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-aws-network/blob/master/LICENSE) for full details.
