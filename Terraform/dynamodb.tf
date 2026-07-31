resource "aws_dynamodb_table" "reviews" {
  name         = "production-reviews"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "review_id"

  attribute {
    name = "review_id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.app_key.arn
  }

  tags = {
    Name        = "compie-reviews-table"
    Environment = var.environment
  }
}