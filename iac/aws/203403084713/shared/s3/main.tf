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

resource "aws_s3_bucket" "datahub-git-lfs" {
  bucket = "datahub-git-lfs"
  tags = {
    Name     = "datahub-git-lfs"
    cdsi-app = "datahub"
  }
}

resource "aws_s3_bucket_versioning" "datahub-git-lfs-versioning" {
  bucket = aws_s3_bucket.datahub-git-lfs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "datahub-git-lfs-access" {
  bucket = aws_s3_bucket.datahub-git-lfs.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}