locals {
  account_id                  = data.aws_caller_identity.current.account_id
  permissions_boundary_policy = "AutomationOrUserServiceRolePermissions"
}

data "aws_caller_identity" "current" {}

# Bedrock itself lives in a separate AWS account (490004633549, where the
# org's Bedrock credits are provisioned). A role in this account
# (175678591974) has no IAM trust relationship with resources over there,
# so IRSA alone can't grant Bedrock access — only the SAML-federated
# identity actually recognized in 490004633549 can (same mechanism
# LibreChat/cbioagent/biomni/cell-explorer already use). This module
# therefore grants IRSA access only to the thing that *is* same-account:
# reading the SAML login secret out of Secrets Manager so the
# acgc-aws-credentials-refresher CronJob can log in and write the
# resulting temporary AWS credentials into a k8s Secret. Modeled on
# knowledgesystems-k8s-deployment's existing k8s-aws-creds-manager
# (argocd/aws/203403084713/.../k8s-aws-creds-manager), single-account
# variant — ACGC only needs 490004633549, not the multi-account list that
# pattern supports for the cost dashboard's use case.
resource "aws_secretsmanager_secret" "acgcAwsCredsManager" {
  name        = "user-acgc-aws-creds-manager"
  description = "SAML login (saml2aws) creds for ACGC's Bedrock-account (490004633549) credential refresher. Value populated out-of-band, not by Terraform."

  tags = {
    cdsi-app   = "acgc"
    cdsi-team  = "oncokb"
    cdsi-owner = "luc2@mskcc.org"
  }
}

resource "aws_iam_policy" "userServicePolicyAcgcAwsCredsManager" {
  name        = "userServicePolicyAcgcAwsCredsManager"
  path        = "/"
  description = "Allows the ACGC creds-refresher CronJob to read its SAML login secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSamlLoginSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.acgcAwsCredsManager.arn]
      }
    ]
  })

  tags = {
    cdsi-app   = "acgc"
    cdsi-team  = "oncokb"
    cdsi-owner = "luc2@mskcc.org"
  }
}

resource "aws_iam_role" "userServiceRoleAcgcAwsCredsManager" {
  name        = "userServiceRoleAcgcAwsCredsManager"
  description = "IRSA role for the ACGC AWS-creds-refresher CronJob"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/${var.cluster_oidc_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_provider_arn}:sub" = "system:serviceaccount:default:acgc-aws-creds-manager-pod-restarter"
          }
        }
      }
    ]
  })

  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/${local.permissions_boundary_policy}"

  tags = {
    cdsi-app   = "acgc"
    cdsi-team  = "oncokb"
    cdsi-owner = "luc2@mskcc.org"
  }
}

resource "aws_iam_role_policy_attachment" "userServicePolicyAttachmentAcgcAwsCredsManager" {
  policy_arn = aws_iam_policy.userServicePolicyAcgcAwsCredsManager.arn
  role       = aws_iam_role.userServiceRoleAcgcAwsCredsManager.name
}
