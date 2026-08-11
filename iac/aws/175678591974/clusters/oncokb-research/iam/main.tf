locals {
  account_id                  = data.aws_caller_identity.current.account_id
  account_region              = var.aws_region
  permissions_boundary_policy = "AutomationOrUserServiceRolePermissions"
}

data "aws_caller_identity" "current" {}

# Bedrock itself lives in a separate AWS account (490004633549, where the
# org's Bedrock credits are provisioned). A role in this account
# (175678591974) has no IAM trust relationship with resources over there,
# so IRSA alone can't grant Bedrock access — only the SAML-federated
# identity actually recognized in 490004633549 can (same mechanism
# LibreChat/cbioagent/biomni/cell-explorer already use). This role
# therefore grants IRSA access only to the thing that *is* same-account:
# reading the SAML login secret out of Secrets Manager so the
# acgc-aws-credentials-refresher CronJob can log in and write the
# resulting temporary AWS credentials into a k8s Secret. Modeled on
# knowledgesystems-k8s-deployment's existing k8s-aws-creds-manager
# (iac/aws/203403084713/clusters/cbioportal-prod/iam — the IAM side —
# and argocd/aws/203403084713/.../k8s-aws-creds-manager — the k8s side),
# single-account variant since ACGC only ever needs 490004633549, not the
# multi-account list that pattern supports for the cost dashboard's use
# case.
#
# The secret itself (user-acgc-aws-creds-manager) is defined in the
# shared account-wide secretsmanager module
# (iac/aws/175678591974/shared/secretsmanager), not here — same
# convention as user-k8s-aws-creds-manager, which lives in that
# account's equivalent shared module rather than its cluster's iam/.
# Referenced here by name pattern rather than a cross-module Terraform
# reference, matching how userServicePolicyK8sAwsCredsManager does it.
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
        Resource = ["arn:aws:secretsmanager:${local.account_region}:${local.account_id}:secret:user-acgc-aws-creds-manager*"]
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
