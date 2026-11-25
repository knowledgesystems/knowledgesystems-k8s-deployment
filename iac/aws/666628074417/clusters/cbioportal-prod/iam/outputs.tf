output "cellxgene_s3_mountpoint_role_arn" {
  value       = aws_iam_role.userServiceRoleCellxgeneS3Mountpoint.arn
  description = "ARN of the IAM Role for the cellxgene s3 mountpoint"
}

output "databricks_s3_mountpoint_role_arn" {
  value       = aws_iam_role.userServiceRoleDatabricksS3Mountpoint.arn
  description = "ARN of the IAM Role for the databricks s3 mountpoint"
}

output "msk_static_files_reader_role_arn" {
  value       = aws_iam_role.userServiceRoleMskStaticFilesReader.arn
  description = "ARN of the IAM Role the MSK portals use to read the msk-static-files bucket"
}
