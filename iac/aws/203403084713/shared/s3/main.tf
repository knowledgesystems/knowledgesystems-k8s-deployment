resource "aws_servicecatalog_provisioned_product" "cBioPortal_Public_DB_Dump" {
  name                       = "cBioPortal_Public_DB_Dump"
  product_id                 = "prod-5ghnhr2n5wnx4"
  provisioning_artifact_name = "1.3.3"

  provisioning_parameters {
    key   = "ACMCertificateArn"
    value = "arn:aws:acm:us-east-1:203403084713:certificate/b3a29c0f-0e1a-4b58-b4ba-32d38492a16a"
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