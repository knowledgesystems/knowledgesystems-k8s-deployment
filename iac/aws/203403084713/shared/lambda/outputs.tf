output "github_lfs_api_url" {
  description = "API Gateway URL for the GitHub LFS broker Lambda"
  value       = aws_apigatewayv2_stage.github_lfs_api_gw_stage.invoke_url
}
