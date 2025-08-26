resource "aws_servicecatalog_provisioned_product" "htan_files_s3_cdn" {
  name                     = "htan_files_s3_cdn"
  product_id               = "prod-5ghnhr2n5wnx4"
  provisioning_artifact_id = "pa-wupvv4plqlhoa"
  path_id                  = "lpv3-bgiovxbn4vdko"

  provisioning_parameters {
    key   = "DomainName"
    value = "htan.assets.cbioportal.org"
  }

  provisioning_parameters {
    key   = "ACMCertificateArn"
    value = "arn:aws:acm:us-east-1:203403084713:certificate/b3a29c0f-0e1a-4b58-b4ba-32d38492a16a"
  }

  provisioning_parameters {
    key   = "Environment"
    value = "prod"
  }

  # Block non-MSKCC IPs
  provisioning_parameters {
    key   = "Block"
    value = "false"
  }
}