resource "aws_s3_bucket" "cellxgene_data_msk" {
  bucket = "cellxgene-data-msk"
  tags = {
    cdsi-app   = "cellxgene"
    cdsi-owner = "hweej@mskcc.org"
  }
}