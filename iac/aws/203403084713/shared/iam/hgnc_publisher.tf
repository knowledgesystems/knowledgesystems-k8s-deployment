resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "hgnc_publisher" {
  name                 = "userServiceRole-hgnc-study-publisher"
  max_session_duration = 21600
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
      Condition = { StringEquals = {
        "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = "repo:cbioportal-curation-gene-update/datahub:ref:refs/heads/master"
      } }
    }]
  })
}

resource "aws_iam_role_policy" "hgnc_publish" {
  name = "publish-hgnc-study-archives"
  role = aws_iam_role.hgnc_publisher.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = "arn:aws:s3:::cdsi-curation-hgnc"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"]
        Resource = ["arn:aws:s3:::cdsi-curation-hgnc/*.tar.gz", "arn:aws:s3:::cdsi-curation-hgnc/study_list.json"]
      }
    ]
  })
}
