output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.oncokb.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.oncokb.arn
}

output "public_bucket_name" {
  description = "Name of the public S3 bucket"
  value       = aws_s3_bucket.public_oncokb_datahub.bucket
}

output "public_bucket_arn" {
  description = "ARN of the public S3 bucket"
  value       = aws_s3_bucket.public_oncokb_datahub.arn
}

output "public_bucket_base_url" {
  description = "Base URL for public objects in the bucket"
  value       = "https://${aws_s3_bucket.public_oncokb_datahub.bucket}.s3.${var.AWS_REGION}.amazonaws.com"
}
