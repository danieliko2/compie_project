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

# 4. App Username
resource "aws_ssm_parameter" "app_username" {
  name        = "${local.ssm_prefix}/APP_USERNAME"
  description = "Application login username"
  type        = "String"
  value       = var.app_username # Passed via terraform.tfvars or -var CLI flag

  lifecycle {
    ignore_changes = [value] # Keeps existing parameter value if modified out-of-band
  }
}

# 5. App Password (SecureString)
resource "aws_ssm_parameter" "app_password" {
  name        = "${local.ssm_prefix}/APP_PASSWORD"
  description = "Application login password"
  type        = "SecureString"
  value       = var.app_password # Passed securely via CLI or variables
  key_id      = aws_kms_key.app_key.id

  lifecycle {
    ignore_changes = [value] # Prevents Terraform from overwriting changes made directly in AWS
  }
}