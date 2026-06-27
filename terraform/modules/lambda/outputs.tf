output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_alias_name" {
  value = aws_lambda_alias.stable.name
}

output "lambda_alias_invoke_arn" {
  value = aws_lambda_alias.stable.invoke_arn
}
