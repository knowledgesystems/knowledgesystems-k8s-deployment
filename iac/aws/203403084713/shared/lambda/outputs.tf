output "github_lfs_function_url" {
  description = "Function URL for the GitHub LFS broker Lambda"
  value       = aws_lambda_function_url.github-lfs.function_url
}
