locals {
  lfs_broker_zip = "${path.module}/lfs-broker-linux-amd64.zip"
}

data "aws_iam_role" "github_lfs_lambda" {
  name = var.GITHUB_LFS_ROLE_NAME
}

data "aws_s3_bucket" "github_lfs" {
  bucket = var.DATAHUB_LFS_BUCKET_NAME
}

resource "null_resource" "download_lfs_broker" {
  triggers = {
    version = var.GIT_LFS_S3_VERSION
  }

  provisioner "local-exec" {
    command = "curl -sL -o ${local.lfs_broker_zip} https://github.com/knowledgesystems/git-lfs-s3/releases/download/${var.GIT_LFS_S3_VERSION}/lfs-broker-linux-amd64.zip"
  }
}

resource "aws_lambda_function" "github_lfs_function" {
  function_name = "github-lfs"
  role          = data.aws_iam_role.github_lfs_lambda.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architectures = ["x86_64"]
  timeout       = 30

  filename         = local.lfs_broker_zip
  source_code_hash = base64sha256(var.GIT_LFS_S3_VERSION)

  environment {
    variables = {
      S3_BUCKET       = data.aws_s3_bucket.github_lfs.id
      LFS_SECRET_NAME = var.LFS_SECRET_NAME
    }
  }

  depends_on = [null_resource.download_lfs_broker]
}

resource "aws_apigatewayv2_api" "github_lfs_api_gw" {
  name          = "github-lfs-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "github_lfs_api_gw_stage" {
  api_id      = aws_apigatewayv2_api.github_lfs_api_gw.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "github_lfs_api_gw_integration" {
  api_id                 = aws_apigatewayv2_api.github_lfs_api_gw.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.github_lfs_function.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "github_lfs_api_gw_route" {
  api_id    = aws_apigatewayv2_api.github_lfs_api_gw.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.github_lfs_api_gw_integration.id}"
}

resource "aws_lambda_permission" "github_lfs_api_gw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_lfs_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.github_lfs_api_gw.execution_arn}/*/*"
}