resource "random_id" "github_lfs_api_key" {
  for_each    = toset(var.GITHUB_LFS_CURATORS)
  byte_length = 32
}

resource "aws_secretsmanager_secret" "user-github-lfs-api-keys" {
  name        = "user-github-lfs-api-keys"
  description = "Curator API keys for GitHub LFS Lambda upload authentication"
}

resource "aws_secretsmanager_secret_version" "github-lfs-api-keys" {
  secret_id = aws_secretsmanager_secret.user-github-lfs-api-keys.id
  secret_string = jsonencode({
    for curator in var.GITHUB_LFS_CURATORS :
    curator => random_id.github_lfs_api_key[curator].hex
  })
}