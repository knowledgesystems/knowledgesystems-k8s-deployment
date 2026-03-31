# GitHub LFS

## Overview
GitHub LFS for cBioPortal [Datahub](https://github.com/cBioPortal/datahub) is backed by AWS infrastructure: an S3 bucket for object storage, a Lambda function (lfs-broker) that implements the [Git LFS Batch API](https://github.com/git-lfs/git-lfs/blob/main/docs/api/batch.md), and Secrets Manager for curator API key authentication. Downloads are public; uploads require an API key.

The Lambda source code lives in a separate repository ([cdsi/git-lfs-s3](https://github.mskcc.org/cdsi/git-lfs-s3)) and is referenced as a git submodule.

## Infrastructure

The setup spans four Terraform modules under `iac/aws/203403084713/shared/`. Each is managed as a separate state.

| Module | Resources | Path |
|---|---|---|
| **s3** | S3 bucket, versioning, public access block, bucket policy | `s3/main.tf` |
| **iam** | Lambda execution role, managed policy attachment, inline policy (S3 + Secrets Manager) | `iam/main.tf` |
| **secretsmanager** | Secret for curator API keys, auto-generated keys via `random_id` | `secretsmanager/main.tf` |
| **lambda** | Lambda function, Function URL, public invoke permissions | `lambda/main.tf` |

### Cross-Module References
Since these modules are in separate Terraform states, they use `data` sources to reference each other's resources at plan time (rather than hardcoded ARNs):

This means Terraform will fail at plan time if a referenced resource doesn't exist yet. Apply modules in this order:

1. `s3` (bucket must exist first)
2. `iam` (role references the bucket)
3. `secretsmanager` (independent, but must exist before Lambda runs)
4. `lambda` (references role and bucket)

After IAM is applied, re-apply `s3` so the bucket policy can resolve the role ARN.

## Curator API Keys

### How Keys Work
Curator API keys are stored in AWS Secrets Manager as a JSON object mapping curator names to hex keys. The Lambda reads this secret to authenticate upload requests via Basic Auth or Bearer token.

Keys are generated automatically by Terraform using `random_id` (32 bytes / 64 hex characters, equivalent to `openssl rand -hex 32`). No secrets are stored in the repository.

### Viewing Keys
After applying the secretsmanager module:
```bash
cd iac/aws/203403084713/shared/secretsmanager
terraform output -json github_lfs_api_keys
```

### Adding a New Curator
Add the curator name to the `GITHUB_LFS_CURATORS` variable in `secretsmanager/variables.tf` and apply:
```bash
terraform apply
```

### Rotating a Single Key
Taint the specific curator's `random_id` resource and apply:
```bash
terraform taint 'random_id.github_lfs_api_key["curator-name"]'
terraform apply
```
Only that curator's key is regenerated. All other keys remain unchanged.

### Removing a Curator
Remove the curator name from the `GITHUB_LFS_CURATORS` variable and apply.

## Lambda Source Code (Submodule)

The lfs-broker Go source is pulled in as a git submodule at `lambda/git-lfs-s3/`. Terraform builds it locally during `terraform apply` (requires Go installed).

### First-Time Clone
When cloning this repo, initialize the submodule:
```bash
git clone --recurse-submodules <repo-url>
# or, if already cloned:
git submodule update --init
```

### Updating the Lambda Code
Pull the latest from the source repo and commit the submodule pointer:
```bash
cd iac/aws/203403084713/shared/lambda/git-lfs-s3
git pull origin master
cd ..
git add git-lfs-s3
git commit -m "Update git-lfs-s3 submodule"
```
Then `terraform apply` in the lambda module to rebuild and deploy.

## Client Configuration
The function URLs for lambda functions can be retrieved with:
```bash
cd iac/aws/203403084713/shared/lambda
terraform output github_lfs_function_url
```
