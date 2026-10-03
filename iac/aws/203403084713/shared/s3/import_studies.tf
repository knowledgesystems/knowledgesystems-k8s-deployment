resource "aws_s3_bucket" "import_studies" {
  bucket = "cbioportal-import-studies-203403084713"
  tags = {
    cdsi-app   = "cmo-pipelines"
    cdsi-owner = "jamesko@mskcc.org"
  }
}

resource "aws_s3_bucket_public_access_block" "import_studies" {
  bucket                  = aws_s3_bucket.import_studies.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "import_studies" {
  bucket = aws_s3_bucket.import_studies.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "import_studies" {
  bucket = aws_s3_bucket.import_studies.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AirflowReadStudies"
        Effect    = "Allow"
        Principal = { AWS = local.databricks_msk_csi_role_arn }
        Action    = ["s3:ListBucket", "s3:GetObject", "s3:GetBucketLocation"]
        Resource  = [aws_s3_bucket.import_studies.arn, "${aws_s3_bucket.import_studies.arn}/*"]
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.import_studies.arn, "${aws_s3_bucket.import_studies.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }
    ]
  })
}

output "import_studies_bucket" {
  value = aws_s3_bucket.import_studies.id
}
