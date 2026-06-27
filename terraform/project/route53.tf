locals {
  has_domain = var.domain_name != ""
  # example: app.dev.example.com
  api_fqdn = local.has_domain ? "${var.app_name}.${var.app_env}.${var.domain_name}" : ""

  # friendly url when custom domain is enabled
  custom_api_endpoint       = local.has_domain ? "https://${local.api_fqdn}" : ""
  sample_recommendation_url = local.has_domain ? "${local.custom_api_endpoint}/recommendations?style=Italian&open_at=12:00" : "${module.api_gateway.api_endpoint}/recommendations?style=Italian&open_at=12:00"
}

data "aws_route53_zone" "this" {
  count        = local.has_domain ? 1 : 0
  name         = var.zone_id == "" ? var.domain_name : null
  zone_id      = var.zone_id != "" ? var.zone_id : null
  private_zone = false
}

resource "aws_acm_certificate" "api" {
  count             = local.has_domain ? 1 : 0
  domain_name       = local.api_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-api-cert" })
}

# dns records used by acm validation
resource "aws_route53_record" "cert_validation" {
  for_each = local.has_domain ? {
    for opt in aws_acm_certificate.api[0].domain_validation_options : opt.domain_name => opt
  } : {}

  zone_id         = data.aws_route53_zone.this[0].zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  ttl             = 60
  records         = [each.value.resource_record_value]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "api" {
  count                   = local.has_domain ? 1 : 0
  certificate_arn         = aws_acm_certificate.api[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

resource "aws_apigatewayv2_domain_name" "this" {
  count       = local.has_domain ? 1 : 0
  domain_name = local.api_fqdn

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api[0].certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.api]

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-api-domain" })
}

# connect the custom domain to the default api stage
resource "aws_apigatewayv2_api_mapping" "this" {
  count       = local.has_domain ? 1 : 0
  api_id      = module.api_gateway.api_id
  domain_name = aws_apigatewayv2_domain_name.this[0].id
  stage       = "$default"
}

resource "aws_route53_record" "api" {
  count   = local.has_domain ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = local.api_fqdn
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
