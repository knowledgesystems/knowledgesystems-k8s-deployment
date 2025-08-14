locals {
  account_id                     = data.aws_caller_identity.current.account_id
  permissions_boundary_policy    = "AutomationOrUserServiceRolePermissions"
  cellxgene_s3_mountpoint_bucket = "cellxgene-data"
}

data "aws_caller_identity" "current" {}

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
              "${var.cluster_oidc_provider_arn}:aud" = "sts.amazonaws.com"
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

resource "aws_iam_role_policy_attachment" "userServicePolicyAttachmentCellxgeneS3Mountpoint" {
  policy_arn = aws_iam_policy.userServicePolicyCellxgeneS3Mountpoint.arn
  role       = aws_iam_role.userServiceRoleCellxgeneS3Mountpoint.name
}