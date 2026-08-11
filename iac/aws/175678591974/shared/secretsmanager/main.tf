resource "random_password" "oncokb-public-db-pw" {
  count            = 1
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "user-oncokb-public-db-pw" {
  name        = "user-oncokb-public-db-pw"
  description = "RDS master password for oncokb-public-db"
}

resource "aws_secretsmanager_secret_version" "oncokb-public-db-pw" {
  secret_id     = aws_secretsmanager_secret.user-oncokb-public-db-pw.id
  secret_string = random_password.oncokb-public-db-pw[0].result
}

# SAML login (saml2aws) creds for ACGC's Bedrock-account (490004633549)
# credential refresher — see argocd/aws/175678591974/clusters/oncokb-research/
# apps/agentic-cancer-gene-classification/oncokb_acgc_aws_creds_refresher.yaml.
# Write-only, same pattern as user-k8s-aws-creds-manager below/elsewhere: the
# value is only ever set via `terraform apply -var=ACGC_AWS_CREDS_MANAGER_VALUE=...`
# (never committed) or the AWS CLI directly, and is never persisted to state.
resource "aws_secretsmanager_secret" "user-acgc-aws-creds-manager" {
  name        = "user-acgc-aws-creds-manager"
  description = "SAML login creds ACGC uses to refresh its Bedrock-account (490004633549) AWS credentials"
}

ephemeral "aws_secretsmanager_secret_version" "acgc_aws_creds_manager_current" {
  secret_id = aws_secretsmanager_secret.user-acgc-aws-creds-manager.id
}

resource "aws_secretsmanager_secret_version" "acgc_aws_creds_manager" {
  secret_id                = aws_secretsmanager_secret.user-acgc-aws-creds-manager.id
  secret_string_wo         = coalesce(var.ACGC_AWS_CREDS_MANAGER_VALUE, ephemeral.aws_secretsmanager_secret_version.acgc_aws_creds_manager_current.secret_string)
  secret_string_wo_version = var.ACGC_AWS_CREDS_MANAGER_VERSION
}
