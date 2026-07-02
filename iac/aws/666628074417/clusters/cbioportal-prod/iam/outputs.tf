output "cellxgene_s3_mountpoint_role_arn" {
  value       = aws_iam_role.userServiceRoleCellxgeneS3Mountpoint.arn
  description = "ARN of the IAM Role for the cellxgene s3 mountpoint"
}

output "hackathon_s3_mountpoint_role_arn" {
  value       = aws_iam_role.userServiceRoleHackathonS3Mountpoint.arn
  description = "ARN of the IAM Role for the hackathon s3 mountpoint"
}
