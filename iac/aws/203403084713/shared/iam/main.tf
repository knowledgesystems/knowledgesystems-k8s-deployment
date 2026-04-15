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

# --- Databricks Pipelines Role & Policies ---

resource "aws_iam_role" "userServiceRole-pipelines-databricks" {
  name        = "userServiceRole-pipelines-databricks"
  description = "Role for Databricks Unity Catalog to access the cbioportal datahub bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.account_id}:role/userServiceRole-pipelines-databricks",
            var.DATABRICKS_UNITY_CATALOG_ROLE_ARN
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.DATABRICKS_EXTERNAL_ID
          }
        }
      }
    ]
  })

  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"
}

resource "aws_iam_policy" "userServicePolicy-pipelineBucketAccess" {
  name        = "userServicePolicy-pipelineBucketAccess"
  description = "S3 read/write/delete access to the datahub bucket for Databricks pipelines"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          data.aws_s3_bucket.github-lfs.arn,
          "${data.aws_s3_bucket.github-lfs.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${local.account_id}:role/userServiceRole-pipelines-databricks"
      }
    ]
  })
}

resource "aws_iam_policy" "userServicePolicy-pipelinesBucketNotifications" {
  name        = "userServicePolicy-pipelinesBucketNotifications"
  description = "S3 event notifications via SNS/SQS for the datahub bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManagedFileEventsSetupStatement"
        Effect = "Allow"
        Action = [
          "s3:GetBucketNotification",
          "s3:PutBucketNotification",
          "sns:ListSubscriptionsByTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:CreateTopic",
          "sns:TagResource",
          "sns:Publish",
          "sns:Subscribe",
          "sqs:CreateQueue",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:TagQueue",
          "sqs:PurgeQueue",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          data.aws_s3_bucket.github-lfs.arn,
          "arn:aws:sqs:*:*:*",
          "arn:aws:sns:*:*:*"
        ]
      },
      {
        Sid    = "ManagedFileEventsListStatement"
        Effect = "Allow"
        Action = [
          "sqs:ListQueues",
          "sqs:ListQueueTags",
          "sns:ListTopics"
        ]
        Resource = "*"
      },
      {
        Sid    = "ManagedFileEventsTeardownStatement"
        Effect = "Allow"
        Action = [
          "sns:Unsubscribe",
          "sns:DeleteTopic",
          "sqs:DeleteQueue"
        ]
        Resource = [
          "arn:aws:sqs:*:*:*",
          "arn:aws:sns:*:*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pipelines-databricks-bucket-access" {
  role       = aws_iam_role.userServiceRole-pipelines-databricks.name
  policy_arn = aws_iam_policy.userServicePolicy-pipelineBucketAccess.arn
}

resource "aws_iam_role_policy_attachment" "pipelines-databricks-bucket-notifications" {
  role       = aws_iam_role.userServiceRole-pipelines-databricks.name
  policy_arn = aws_iam_policy.userServicePolicy-pipelinesBucketNotifications.arn
}