locals {
  rules_transform_yaml = yamldecode(var.config)
  rules_rewrite_url    = local.rules_transform_yaml.rewrite_url
}

resource "cloudflare_ruleset" "transform_rewrite_url" {
  zone_id = var.cloudflare_zone_id

  kind  = "zone"
  phase = "http_request_transform"
  name  = "Transform Rules"

  dynamic "rules" {
    for_each = local.rules_rewrite_url

    content {
      enabled = lookup(rules.value, "enabled", true)
      action  = "rewrite"

      description = rules.value.name
      expression  = rules.value.expression

      action_parameters {
        uri {
          dynamic "path" {
            for_each = can(rules.value.path) ? [rules.value.path] : []

            content {
              expression = lookup(path.value, "dynamic", false) ? path.value.value : null
              value      = lookup(path.value, "dynamic", false) ? null : path.value.value
            }
          }

          dynamic "query" {
            for_each = can(rules.value.query) ? [rules.value.query] : []

            content {
              expression = lookup(query.value, "dynamic", false) ? query.value.value : ""
              value      = lookup(query.value, "dynamic", false) ? "" : query.value.value
            }
          }
        }
      }
    }
  }
}
