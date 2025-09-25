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
