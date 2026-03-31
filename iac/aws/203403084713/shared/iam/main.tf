locals {
  account_id                  = data.aws_caller_identity.current.account_id
  permissions_boundary_policy = "AutomationOrUserServiceRolePermissions"
}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "github-lfs" {
  bucket = var.DATAHUB_LFS_BUCKET_NAME
}

resource "aws_iam_role" "userServiceRole-github-lfs-lambda-role" {
  name = "userServiceRole-github-lfs-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"
}

resource "aws_iam_role_policy_attachment" "userServicePolicyAttachment-github-lfs-lambda-basic-execution" {
  role       = aws_iam_role.userServiceRole-github-lfs-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "github-lfs-s3-access" {
  name = "github-lfs-s3-access"
  role = aws_iam_role.userServiceRole-github-lfs-lambda-role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${data.aws_s3_bucket.github-lfs.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:${var.AWS_REGION}:${local.account_id}:secret:${var.GITHUB_LFS_SECRET_NAME}*"
      }
    ]
  })
}