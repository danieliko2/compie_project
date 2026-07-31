# KMS Key for Encryption at Rest (Database & Secrets)
resource "aws_kms_key" "app_key" {
  description             = "KMS key for compie_app encryption at rest"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "app_key_alias" {
  name          = "alias/compie-app-key"
  target_key_id = aws_kms_key.app_key.key_id
}