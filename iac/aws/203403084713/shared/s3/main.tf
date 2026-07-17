data "aws_caller_identity" "current" {}

data "aws_iam_role" "github-lfs-lambda-role" {
  name = var.GITHUB_LFS_LAMBDA_ROLE_NAME
}

locals {
  datahub_bucket_name = one([for o in aws_servicecatalog_provisioned_product.cbioportal-datahub.outputs : o.value if o.key == "ContentBucket"])
  datahub_cf_dist_id  = one([for o in aws_servicecatalog_provisioned_product.cbioportal-datahub.outputs : o.value if o.key == "CloudFrontDistribution"])

  # Service Catalog provisioned bucket read by the MSK (666628074417) airflow
  # importer via the S3 Mountpoint CSI driver. The MSK-side IAM role is defined
  # in iac/aws/666628074417/clusters/cbioportal-prod/iam/main.tf.
  databricks_target_bucket_name = "sc-203403084713-pp-4rxlzd426npxu-bucket-kswubqqre3jr"
  databricks_msk_csi_role_arn   = "arn:aws:iam::666628074417:role/userServiceRoleDatabricksS3Mountpoint"
}

resource "aws_servicecatalog_provisioned_product" "cBioPortal_Public_DB_Dump" {
  name                       = "cBioPortal_Public_DB_Dump"
  product_id                 = "prod-5ghnhr2n5wnx4"
  provisioning_artifact_name = "1.3.3"

  provisioning_parameters {
    key   = "ACMCertificateArn"
    value = var.S3_CDN_CERT_ARN
  }

  provisioning_parameters {
    key   = "DomainName"
    value = "public-db-dump.assets.cbioportal.org"
  }

  # The product doesn't allow updating tags, so ignore for lifecycle changes.
  lifecycle {
    ignore_changes = [tags_all, tags]
  }
}

resource "aws_servicecatalog_provisioned_product" "cbioportal-datahub" {
  name                       = "cbioportal-datahub"
  product_id                 = "prod-5ghnhr2n5wnx4"
  provisioning_artifact_name = "1.3.5"

  provisioning_parameters {
    key   = "ACMCertificateArn"
    value = var.S3_CDN_CERT_ARN
  }

  provisioning_parameters {
    key   = "DomainName"
    value = "datahub.assets.cbioportal.org"
  }

  provisioning_parameters {
    key   = "Block"
    value = "false"
  }

  provisioning_parameters {
    key   = "Environment"
    value = "prod"
  }

}

resource "aws_s3_bucket" "cellxgene_data" {
  bucket = "cellxgene-data"
  tags = {
    cdsi-app   = "cellxgene"
    cdsi-owner = "hweej@mskcc.org"
  }
}

resource "aws_servicecatalog_provisioned_product" "g2s-dump" {
  name                       = "g2s-dump"
  product_id                 = "prod-5ghnhr2n5wnx4"
  provisioning_artifact_name = "1.3.5"

  provisioning_parameters {
    key   = "ACMCertificateArn"
    value = var.S3_CDN_CERT_ARN
  }

  provisioning_parameters {
    key   = "DomainName"
    value = "g2s.assets.cbioportal.org"
  }

  provisioning_parameters {
    key   = "Block"
    value = "false"
  }

  provisioning_parameters {
    key   = "Environment"
    value = "prod"
  }

}

resource "aws_s3_bucket_policy" "cbioportal-datahub-policy" {
  bucket     = local.datahub_bucket_name
  depends_on = [aws_servicecatalog_provisioned_product.cbioportal-datahub]

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "*"
        Resource  = "arn:aws:s3:::${local.datahub_bucket_name}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowCFNGet"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${local.datahub_bucket_name}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${local.datahub_cf_dist_id}"
          }
        }
      },
      {
        Sid       = "DenyPublicReadLFS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${local.datahub_bucket_name}/${var.LFS_PATH_PREFIX}/*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalArn" = data.aws_iam_role.github-lfs-lambda-role.arn
          }
        }
      }
    ]
  })
}


# Read existing bucket policy so we can merge rather than replace
data "aws_s3_bucket_policy" "databricks_target_existing" {
  bucket = local.databricks_target_bucket_name
}

locals {
  databricks_existing_policy_json = try(data.aws_s3_bucket_policy.databricks_target_existing.policy, "{}")
  databricks_existing_policy      = try(jsondecode(local.databricks_existing_policy_json), { Version = "2012-10-17", Statement = [] })
}

resource "aws_s3_bucket_policy" "databricks-target-msk-csi-policy" {
  bucket = local.databricks_target_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      local.databricks_existing_policy.Statement,
      [
        {
          Sid    = "AllowMskAirflowCsiReadOnly"
          Effect = "Allow"
          Principal = {
            AWS = local.databricks_msk_csi_role_arn
          }
          Action = [
            "s3:ListBucket",
            "s3:GetObject"
          ]
          Resource = [
            "arn:aws:s3:::${local.databricks_target_bucket_name}",
            "arn:aws:s3:::${local.databricks_target_bucket_name}/*"
          ]
        },
        {
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            "arn:aws:s3:::${local.databricks_target_bucket_name}",
            "arn:aws:s3:::${local.databricks_target_bucket_name}/*"
          ]
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        }
      ]
    )
  })
}
