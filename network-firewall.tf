# AWS Network Firewall associated to a VPC with a firewall policy
resource "aws_networkfirewall_firewall" "default" {
  count               = var.network_firewall ? 1 : 0
  name                = "${var.name}-Network-Firewall"
  description         = "Managed by terrfaform"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.default[0].arn
  vpc_id              = aws_vpc.default.id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall[*].id
    content {
      subnet_id = subnet_mapping.value
    }
  }

  depends_on = [aws_vpc.default]
}

# Firewall policy with stateful and stateless firewall rules
resource "aws_networkfirewall_firewall_policy" "default" {
  count       = var.network_firewall ? 1 : 0
  name        = "${var.name}-Default-Policy"
  description = "Managed by terraform"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.stateless_forward[0].arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_domain[0].arn
    }
    dynamic "stateful_rule_group_reference" {
      for_each = aws_networkfirewall_rule_group.stateful_custom
      content {
        resource_arn = stateful_rule_group_reference.value.arn
      }
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_default[0].arn
    }
  }
}

# Stateless rule forwarding all to stateful rules
resource "aws_networkfirewall_rule_group" "stateless_forward" {
  count    = var.network_firewall ? 1 : 0
  capacity = 100
  name     = "${var.name}-Stateless-Default"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 100
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
        stateless_rule {
          priority = 50
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              protocols = [1]
            }
          }
        }
      }
    }
  }
}

# Statefull rule to block domain list
resource "aws_networkfirewall_rule_group" "stateful_domain" {
  count    = var.network_firewall ? 1 : 0
  capacity = 100
  name     = "${var.name}-Stateful-Domains"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = var.firewall_domain_list
      }
    }
  }
}

# Statefull custom rules
resource "aws_networkfirewall_rule_group" "stateful_custom" {
  count    = var.network_firewall && length(var.firewall_custom_rules) > 0 ? 1 : 0
  capacity = 100
  name     = "${var.name}-Stateful-Custom"
  type     = "STATEFUL"
  rules    = <<EOT
  %{for rule in var.firewall_custom_rules}
  ${rule}
  %{endfor}
  EOT
}

# Statefull rule to block any TCP
resource "aws_networkfirewall_rule_group" "stateful_default" {
  count    = var.network_firewall ? 1 : 0 && var.enable_firewall_default_rule
  capacity = 100
  name     = "${var.name}-Stateful-Default"
  type     = "STATEFUL"
  rules    = <<-EOT
  pass ip $EXTERNAL_NET any -> $HOME_NET any (msg:"Allow ingress traffic"; sid: 1000002; rev:1;)
  drop tcp any any -> any any (flow:established,to_server; msg:"Deny all other TCP traffic"; sid: 1000003; rev:1;)
  EOT
}