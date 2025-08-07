output "cellxgene_s3_mountpoint_role_arn" {
  values = aws_iam_role.cellxgene_s3_mountpoint_role
  description = "ARN of the IAM Role for the cellxgene s3 mountpoint"
}