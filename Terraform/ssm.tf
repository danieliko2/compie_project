locals {
  ssm_prefix = "/${var.environment}/compie_app"
}

# 1. DynamoDB Table Name Reference
resource "aws_ssm_parameter" "dynamodb_table" {
  name        = "${local.ssm_prefix}/DYNAMODB_TABLE"
  description = "DynamoDB table name for reviews"
  type        = "String"
  value       = aws_dynamodb_table.reviews.name
}

# 2. Container Port
resource "aws_ssm_parameter" "container_port" {
  name        = "${local.ssm_prefix}/PORT"
  description = "Application runtime port"
  type        = "String"
  value       = tostring(var.container_port)
}

# 3. AWS Region
resource "aws_ssm_parameter" "aws_region" {
  name        = "${local.ssm_prefix}/AWS_REGION"
  description = "AWS Region deployment target"
  type        = "String"
  value       = var.aws_region
}