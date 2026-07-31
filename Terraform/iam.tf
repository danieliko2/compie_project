data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.environment}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# 1. Standard SSM Managed Instance Core (For SSM Session Manager / Shell access)
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 2. ECR Read-Only
resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. DynamoDB Read/Write Policy
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.environment}-EC2DynamoDBAccess"
  description = "Allows EC2 to access compie_reviews DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.reviews.arn
      }
    ]
  })
}

# 4. SSM Parameter Store & KMS Decrypt Read Policy
resource "aws_iam_policy" "ssm_read_policy" {
  name        = "${var.environment}-EC2SSMReadAccess"
  description = "Allows reading parameters from SSM Parameter Store and decrypting via custom KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/compie_app/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        # Updated to reference your custom KMS key resource instead of the AWS managed alias
        Resource = aws_kms_key.app_key.arn
      }
    ]
  })
}

# Attach new policies
resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_role_policy_attachment" "ssm_read_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ssm_read_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}