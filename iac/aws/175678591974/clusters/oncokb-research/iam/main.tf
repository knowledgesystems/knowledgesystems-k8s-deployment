locals {
  account_id                  = data.aws_caller_identity.current.account_id
  permissions_boundary_policy = "AutomationOrUserServiceRolePermissions"
}

data "aws_caller_identity" "current" {}

# Lets the AGCG pod invoke Claude models via Bedrock, using IRSA instead of a
# static API key. Scoped to the "us." cross-region inference profiles the app
# actually uses (bare foundation-model IDs are rejected by Bedrock for these
# models — see agentic-cancer-gene-classification#40), plus the underlying
# foundation models those profiles route to, since a US cross-region profile
# can dispatch to any of us-east-1/us-east-2/us-west-2 depending on capacity.
resource "aws_iam_policy" "userServicePolicyAcgcBedrock" {
  name        = "userServicePolicyAcgcBedrock"
  path        = "/"
  description = "Allows AGCG to invoke Anthropic Claude models via Bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeClaudeInferenceProfiles"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:us-east-1:${local.account_id}:inference-profile/us.anthropic.claude-*"
        ]
      },
      {
        Sid    = "InvokeClaudeFoundationModels"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-*"
        ]
      }
    ]
  })

  tags = {
    cdsi-app   = "acgc"
    cdsi-team  = "oncokb"
    cdsi-owner = "luc2@mskcc.org"
  }
}

resource "aws_iam_role" "userServiceRoleAcgcBedrock" {
  name        = "userServiceRoleAcgcBedrock"
  description = "IRSA role for the AGCG pod's Bedrock access"

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
            "${var.cluster_oidc_provider_arn}:sub" = "system:serviceaccount:default:agentic-cancer-gene-classification"
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

resource "aws_iam_role_policy_attachment" "userServicePolicyAttachmentAcgcBedrock" {
  policy_arn = aws_iam_policy.userServicePolicyAcgcBedrock.arn
  role       = aws_iam_role.userServiceRoleAcgcBedrock.name
}
