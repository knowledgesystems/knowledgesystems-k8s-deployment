locals {
  lfs_broker_src = "${path.module}/git-lfs-s3/lfs-broker"
}

data "aws_iam_role" "github_lfs_lambda" {
  name = var.GITHUB_LFS_ROLE_NAME
}

data "aws_s3_bucket" "github_lfs" {
  bucket = var.DATAHUB_LFS_BUCKET_NAME
}

resource "null_resource" "build_lfs_broker" {
  triggers = {
    source_hash = filesha256("${local.lfs_broker_src}/main.go")
    go_mod_hash = filesha256("${local.lfs_broker_src}/go.mod")
    go_sum_hash = filesha256("${local.lfs_broker_src}/go.sum")
  }

  provisioner "local-exec" {
    command     = "cd ${local.lfs_broker_src} && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -tags lambda.norpc -o bootstrap main.go"
    interpreter = ["/bin/sh", "-c"]
  }
}

data "archive_file" "lfs_broker" {
  type        = "zip"
  source_file = "${local.lfs_broker_src}/bootstrap"
  output_path = "${local.lfs_broker_src}/bootstrap.zip"

  depends_on = [null_resource.build_lfs_broker]
}

resource "aws_lambda_function" "github-lfs" {
  function_name = "github-lfs"
  role          = data.aws_iam_role.github_lfs_lambda.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architectures = ["x86_64"]
  timeout       = 30

  filename         = data.archive_file.lfs_broker.output_path
  source_code_hash = data.archive_file.lfs_broker.output_base64sha256

  environment {
    variables = {
      S3_BUCKET       = data.aws_s3_bucket.github_lfs.id
      LFS_SECRET_NAME = var.LFS_SECRET_NAME
    }
  }
}

resource "aws_lambda_function_url" "github-lfs" {
  function_name      = aws_lambda_function.github-lfs.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "github-lfs-public-access" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.github-lfs.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "github-lfs-public-invoke" {
  statement_id  = "FunctionURLAllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github-lfs.function_name
  principal     = "*"
}