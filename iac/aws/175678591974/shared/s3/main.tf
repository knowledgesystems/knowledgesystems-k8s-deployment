resource "aws_s3_bucket" "oncokb" {
  bucket = "oncokb"

  tags = {
    Name     = "oncokb"
    cdsi-app = "oncokb"
  }
}

resource "aws_s3_bucket_versioning" "oncokb" {
  bucket = aws_s3_bucket.oncokb.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "oncokb" {
  bucket = aws_s3_bucket.oncokb.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public_oncokb_datahub" {
  bucket = "public-oncokb-datahub"

  tags = {
    Name     = "public-oncokb-datahub"
    cdsi-app = "oncokb"
  }
}

resource "aws_s3_bucket_versioning" "public_oncokb_datahub" {
  bucket = aws_s3_bucket.public_oncokb_datahub.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_oncokb_datahub" {
  bucket = aws_s3_bucket.public_oncokb_datahub.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_oncokb_datahub" {
  bucket = aws_s3_bucket.public_oncokb_datahub.id

  depends_on = [aws_s3_bucket_public_access_block.public_oncokb_datahub]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public_oncokb_datahub.arn}/*"
      }
    ]
  })
}
