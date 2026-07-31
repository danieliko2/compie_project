resource "aws_iam_role" "github_actions_ecr_push_role" {
  name = "GitHubActionsRole"

  # Trust Policy (OIDC Relationship)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::367425865577:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:danieliko2*/compie_project*:*"
          }
        }
      }
    ]
  })
}

# Permissions Policy matching your manual setup
resource "aws_iam_role_policy" "github_actions_permissions" {
  name = "GitHubActionsECRPushPolicy"
  role = aws_iam_role.github_actions_ecr_push_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushOperations"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:us-east-1:367425865577:repository/daniel_dev/compie_app"
      },
      {
        Sid    = "AutoScalingRead"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeInstanceRefreshes"
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingInstanceRefresh"
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh"
        ]
        Resource = "arn:aws:autoscaling:us-east-1:367425865577:autoScalingGroup:*:autoScalingGroupName/production-asg-*"
      },
      {
        Sid    = "SSMReadParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:us-east-1:367425865577:parameter/*/compie_app/*"
      },
      {
        Sid    = "KMSDecryptParameters"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:us-east-1:367425865577:key/*"
      }
    ]
  })
}