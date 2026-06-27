output "api_endpoint" {
  value       = module.api_gateway.api_endpoint
  description = "Default API Gateway endpoint."
}

output "custom_api_endpoint" {
  value       = local.has_domain ? local.custom_api_endpoint : null
  description = "Route53 custom API endpoint when domain_name is configured."
}

output "sample_recommendation_url" {
  value       = local.sample_recommendation_url
  description = "Sample URL to test the recommendation API."
}

output "restaurant_table_name" {
  value       = local.table_name
  description = "DynamoDB table used by the recommendation API."
}

output "audit_bucket_name" {
  value       = var.enable_logging ? module.logging["enabled"].audit_bucket_name : null
  description = "Encrypted S3 bucket receiving request audit logs."
}

output "lambda_function_name" {
  value       = module.lambda.lambda_function_name
  description = "Lambda function serving the API."
}
