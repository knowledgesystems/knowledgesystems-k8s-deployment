module "mskscope_portal_bucket" {
  source = "git@github.com:MSK-Staging/terraform-aws-hyc-akamai-s3-website.git?ref=0.2.0"
  bucket_prefix    = var.bucket_prefix
  tags             = var.tags
  org_readers      = var.org_readers
  org_writers      = var.org_writers
  force_destroy    = var.force_destroy
}

// Scope Portal
resource "aws_s3_bucket" "scope_portal_bucket" {
  bucket_prefix = "tf-scope-portal-"
  tags = {
    cdsi-app = "scope-portal"
  }
}

resource "aws_s3_bucket" "scope_log_bucket" {
  bucket_prefix = "tf-scope-logs-"
  tags = {
    cdsi-app = "scope-logs"
  }
}

resource "aws_s3_bucket" "scope_data" {
  bucket_prefix = "tf-scope-data-"
  tags = {
    cdsi-app = "scope-data"
  }
}

resource "aws_s3_bucket" "scope_workflows" {
  bucket_prefix = "tf-scope-workflows-"
  tags = {
    cdsi-app = "scope-workflows"
  }
}
