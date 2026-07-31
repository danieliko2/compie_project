resource "aws_dynamodb_table" "reviews" {
  name         = "compie_reviews"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "review_id"

  attribute {
    name = "review_id"
    type = "S"
  }

  # Cleaned up KMS server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "compie-reviews-table"
    Environment = var.environment
  }
}