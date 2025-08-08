output "cellxgene_s3_mountpoint_role_arn" {
  value       = aws_iam_role.userServiceRoleCellxgeneS3Mountpoint
  description = "ARN of the IAM Role for the cellxgene s3 mountpoint"
}