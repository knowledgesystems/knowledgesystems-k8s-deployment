locals {
  account_id                     = data.aws_caller_identity.current.account_id
  account_region = var.aws_region
  cluster_name = var.cluster_name
  permissions_boundary_policy    = "AutomationOrUserServiceRolePermissions"
  cellxgene_s3_mountpoint_bucket = "cellxgene-data-msk"
  # Cross-account (203403084713) Service Catalog bucket. Requires a matching
  # bucket policy in 203403084713 naming this role as principal.
  databricks_s3_mountpoint_bucket = "sc-203403084713-pp-4rxlzd426npxu-bucket-kswubqqre3jr"
}

data "aws_caller_identity" "current" {}

# S3 mountpoint policy
resource "aws_iam_policy" "userServicePolicyCellxgeneS3Mountpoint" {
  name        = "userServicePolicyCellxgeneS3Mountpoint"
  path        = "/"
  description = "Policy to allow S3 Mountpoint CSI cluster add-on to access S3 buckets"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "MountpointFullBucketAccess",
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.cellxgene_s3_mountpoint_bucket}"
          ]
        },
        {
          "Sid" : "MountpointFullObjectAccess",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:AbortMultipartUpload",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.cellxgene_s3_mountpoint_bucket}/*"
          ]
        }
      ]
    }
  )

  tags = {
    cdsi-owner = "hweej@mskcc.org"
    cdsi-app   = "cellxgene"
    cdsi-team  = "data-visualization"
  }
}

# S3 mountpoint role
resource "aws_iam_role" "userServiceRoleCellxgeneS3Mountpoint" {
  name = "userServiceRoleCellxgeneS3Mountpoint"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRoleWithWebIdentity",
          Principal = {
            Federated = "arn:aws:iam::${local.account_id}:oidc-provider/${var.cluster_oidc_provider_arn}"
          },
          Condition = {
            StringEquals = {
              "${var.cluster_oidc_provider_arn}:aud" = "sts.amazonaws.com",
            }
          }
        }
      ]
    }
  )

  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"

  tags = {
    cdsi-owner = "hweej@mskcc.org"
    cdsi-app   = "cellxgene"
    cdsi-team  = "data-visualization"
  }
}

# S3 mountpoint policy attachment
resource "aws_iam_role_policy_attachment" "userServicePolicyAttachmentCellxgeneS3Mountpoint" {
  policy_arn = aws_iam_policy.userServicePolicyCellxgeneS3Mountpoint.arn
  role       = aws_iam_role.userServiceRoleCellxgeneS3Mountpoint.name
}

# ── Databricks S3 mountpoint ──────────────────────────────────────────
resource "aws_iam_policy" "userServicePolicyDatabricksS3Mountpoint" {
  name        = "userServicePolicyDatabricksS3Mountpoint"
  path        = "/"
  description = "Policy to allow S3 Mountpoint CSI cluster add-on read-only access to the cross-account Databricks S3 bucket"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "MountpointBucketList",
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.databricks_s3_mountpoint_bucket}"
          ]
        },
        {
          "Sid" : "MountpointReadObjectAccess",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.databricks_s3_mountpoint_bucket}/*"
          ]
        }
      ]
    }
  )

  tags = {
    cdsi-owner = "jamesko@mskcc.org"
    cdsi-app   = "cmo-pipelines"
    cdsi-team  = "data-visualization"
  }
}

resource "aws_iam_role" "userServiceRoleDatabricksS3Mountpoint" {
  name = "userServiceRoleDatabricksS3Mountpoint"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRoleWithWebIdentity",
          Principal = {
            Federated = "arn:aws:iam::${local.account_id}:oidc-provider/${var.cluster_oidc_provider_arn}"
          },
          Condition = {
            StringEquals = {
              "${var.cluster_oidc_provider_arn}:aud" = "sts.amazonaws.com",
              "${var.cluster_oidc_provider_arn}:sub" = "system:serviceaccount:airflow:airflow-worker"
            }
          }
        }
      ]
    }
  )

  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"

  tags = {
    cdsi-owner = "jamesko@mskcc.org"
    cdsi-app   = "cmo-pipelines"
    cdsi-team  = "data-visualization"
  }
}

resource "aws_iam_role_policy_attachment" "userServicePolicyAttachmentDatabricksS3Mountpoint" {
  policy_arn = aws_iam_policy.userServicePolicyDatabricksS3Mountpoint.arn
  role       = aws_iam_role.userServiceRoleDatabricksS3Mountpoint.name
}
