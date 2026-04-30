data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# IAM Role for Databricks S3 access via Unity Catalog
resource "aws_iam_role" "databricks_s3" {
  name                 = "userServiceRoleDatabricksS3"
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/AutomationOrUserServiceRolePermissions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            var.DATABRICKS_UNITY_CATALOG_ROLE_ARN,
            "arn:aws:iam::${local.account_id}:role/userServiceRoleDatabricksS3"
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
}

# S3 access policy for Databricks buckets
resource "aws_iam_policy" "databricks_s3" {
  name = "userServiceRole-PDM-DatabricksPolicy"

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
        Resource = flatten([
          for bucket in var.DATABRICKS_S3_BUCKETS : [
            "arn:aws:s3:::${bucket}",
            "arn:aws:s3:::${bucket}/*"
          ]
        ])
      },
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = ["arn:aws:iam::${local.account_id}:role/userServiceRoleDatabricksS3"]
      }
    ]
  })
}

# Bucket notifications policy for Databricks managed file events
resource "aws_iam_policy" "databricks_bucket_notifications" {
  name = "userServiceRole-PDM-DatabricksPolicyBucketNotifications"

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
          "sqs:ChangeMessageVisibility"
        ]
        Resource = concat(
          [for bucket in var.DATABRICKS_S3_BUCKETS : "arn:aws:s3:::${bucket}"],
          ["arn:aws:sqs:*:*:*", "arn:aws:sns:*:*:*"]
        )
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

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "databricks_s3" {
  role       = aws_iam_role.databricks_s3.name
  policy_arn = aws_iam_policy.databricks_s3.arn
}

resource "aws_iam_role_policy_attachment" "databricks_bucket_notifications" {
  role       = aws_iam_role.databricks_s3.name
  policy_arn = aws_iam_policy.databricks_bucket_notifications.arn
}