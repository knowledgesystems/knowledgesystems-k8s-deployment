// Scope Portal
resource "aws_s3_bucket" "scope_portal_bucket" {
  bucket_prefix = "tf-scope-portal-"
  tags = {
    cdsi-app = "scope-portal"
  }
}

// Scope Logs
resource "aws_s3_bucket" "scope_log_bucket" {
  bucket_prefix = "tf-scope-logs-"
  tags = {
    cdsi-app = "scope-logs"
  }
}

// Scope Data
resource "aws_s3_bucket" "scope_data" {
  bucket_prefix = "tf-scope-data-"
  tags = {
    cdsi-app = "scope-data"
  }
}

// Scope workflows
resource "aws_s3_bucket" "scope_workflows" {
  bucket_prefix = "tf-scope-workflows-"
  tags = {
    cdsi-app = "scope-workflows"
  }
}

// Setting ACLs are not permitted
/*
resource "aws_s3_bucket_acl" "scope_portal_bucket_acl" {
  bucket = aws_s3_bucket.scope_portal_bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_acl" "scope_log_bucket_acl" {
  bucket = aws_s3_bucket.scope_log_bucket.id
  acl    = "log-delivery-write"
}
// Logging Action
resource "aws_s3_bucket_logging" "scope_portal_bucket" {
  bucket        = aws_s3_bucket.scope_portal_bucket.id
  target_bucket = aws_s3_bucket.scope_log_bucket.id
  target_prefix = "log/"
}
*/
