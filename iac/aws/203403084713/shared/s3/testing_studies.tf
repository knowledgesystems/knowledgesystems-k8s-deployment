resource "aws_s3_bucket" "testing_studies" {
  bucket = "cdsi-testing"
  tags = {
    cdsi-app   = "cmo-pipelines"
    cdsi-owner = "jamesko@mskcc.org"
  }
}

resource "aws_s3_bucket_public_access_block" "testing_studies" {
  bucket                  = aws_s3_bucket.testing_studies.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "testing_studies" {
  bucket = aws_s3_bucket.testing_studies.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "testing_studies" {
  bucket = aws_s3_bucket.testing_studies.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AirflowReadStudies"
        Effect    = "Allow"
        Principal = { AWS = local.databricks_msk_csi_role_arn }
        Action    = ["s3:ListBucket", "s3:GetObject", "s3:GetBucketLocation"]
        Resource  = [aws_s3_bucket.testing_studies.arn, "${aws_s3_bucket.testing_studies.arn}/*"]
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.testing_studies.arn, "${aws_s3_bucket.testing_studies.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
}

output "testing_studies_bucket" {
  value = aws_s3_bucket.testing_studies.id
}
