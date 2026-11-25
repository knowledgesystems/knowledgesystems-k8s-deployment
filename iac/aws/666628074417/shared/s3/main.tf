resource "aws_s3_bucket" "cellxgene_data_msk" {
  bucket = "cellxgene-data-msk"
  tags = {
    cdsi-app   = "cellxgene"
    cdsi-owner = "hweej@mskcc.org"
  }
}

# Static files the MSK portals serve behind their login. A sidecar in each
# portal pod mirrors the whole bucket into its Spring static location, so an
# object's key is its URL path: embeddings/<map>.json is served at
# /embeddings/<map>.json to anyone logged in to that portal. Read through
# the userServiceRoleMskStaticFilesReader role (clusters/cbioportal-prod/iam).
resource "aws_s3_bucket" "msk_static_files" {
  bucket = "msk-static-files"
}

resource "aws_s3_bucket_public_access_block" "msk_static_files" {
  bucket                  = aws_s3_bucket.msk_static_files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Keeps a replaced or deleted file recoverable.
resource "aws_s3_bucket_versioning" "msk_static_files" {
  bucket = aws_s3_bucket.msk_static_files.id
  versioning_configuration {
    status = "Enabled"
  }
}
