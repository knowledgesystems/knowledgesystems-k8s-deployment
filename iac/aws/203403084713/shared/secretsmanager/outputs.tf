output "github_lfs_api_keys" {
  description = "Generated API keys for GitHub LFS curators"
  value = {
    for curator in var.GITHUB_LFS_CURATORS :
    curator => random_id.github_lfs_api_key[curator].hex
  }
  sensitive = true
}
