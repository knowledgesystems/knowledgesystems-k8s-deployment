resource "aws_servicecatalog_provisioned_product" "cbioportal-public-db-dump" {
  name                       = "cbioportal-public-db-dump"
  product_id                 = "prod-5ghnhr2n5wnx4"
  provisioning_artifact_name = "1.3.5"

  provisioning_parameters {
    key   = "ACMCertificateArn"
    value = "arn:aws:acm:us-east-1:203403084713:certificate/b3a29c0f-0e1a-4b58-b4ba-32d38492a16a"
  }

  provisioning_parameters {
    key   = "DomainName"
    value = "public-db-dump2.assets.cbioportal.org"
  }

  provisioning_parameters {
    key   = "Environment"
    value = "prod"
  }

  tags = {
    # Required by Digits
    "msk:hccp:sc:portfolio-name" = "user-product-catalog"
  }
}