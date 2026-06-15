output "cellxgene_s3_mountpoint_role_arn" {
  value       = aws_iam_role.userServiceRoleCellxgeneS3Mountpoint.arn
  description = "ARN of the IAM Role for the cellxgene s3 mountpoint"
}

output "fargate_pod_execution_role_arn" {
  value = aws_iam_role.userServiceRoleFargatePodExecutionCbioportal.arn
  description = "ARN of the IAM Role for fargate pod execution"
}

output "k8s_aws_creds_manager_role_arn" {
  value       = aws_iam_role.userServiceRoleK8sAwsCredsManager.arn
  description = "ARN of the IAM Role for the k8s AWS credentials manager"
}