# Terraform
The `iac` directory in the repo contains all Terraform configurations for managing the infrastructure across multiple AWS accounts and clusters.

## Prerequisites
1. **saml2aws**: Before you can use terraform, you need to make sure you have setup saml2aws and you are logged in to the correct AWS account in your cli. For all of the following commands, terraform uses your awscli to connect to the aws account. Running these commands in the wrong account can lead to destructive actions.

## AWS CLI Setup
By default, submodules inside `iac` directory use the `default` aws cli profile when running commands. To use a custom profile, set the `TF_VAR_AWS_PROFILE` environment variable.
```shell
export TF_VAR_AWS_PROFILE=<profile-name>
```

## Usage
The `iac` directory contains multiple submodules where each submodule resides under varying nesting levels. Essentially, any subdirectory that has `*.tf` files is a submodule. We don't manage a root module config to avoid accidental disastrous actions and changes that end up impacting multiple accounts at the same time. To make changes to each submodule, change your present working directory to that submodule where the `*.tf` files reside.
1. Change directory into the appropriate module. E.g., Do the following if you want to work on the `eks` setup under the `my-cluster` cluster in account `123456789abc`.
   ```shell
   cd iac/aws/123456789abc/clusters/my-cluster/eks
   ```
2. Now you can make changes to the Terraform files. After making changes format them to ensure consistent formatting.
   ```shell
   terraform fmt
   ```
3. Initialize terraform submodule. This creates intermediate lock and state files.
   ```shell
   terraform init
   ```
4. Pull remote module sources. This requires Git authentication when running for the first time.
   ```shell
   terraform get
   ```
5. Validate your terraform files.
   ```shell
   terraform validate
   ```
6. Dry run to see what changes you are making.
   ```shell
   terraform plan
   ```
7. Apply changes.
   ```shell
   terraform apply
   ```

## Creating New Submodules
If you want to migrate from your current setup to Terraform-based resource management, follow the steps below to create a new submodule in the repo.
1. Create a submodule directory under the appropriate nesting structure.
   ```shell
   mkdir -p iac/aws/<account-number>/clusters/<cluster-name>/<submodule-name>
   
   # E.g. For a s3 submodule under 123456789abc aws account, you would do this
   # mkdir -p iac/aws/123456789abc/clusters/cbioportal-prod/s3
   ```
2. Move into the new module.
   ```shell
   cd iac/aws/<account-number>/clusters/<cluster-name>/<submodule-name>
   ```
3. Create a `terraform.tf` file for the terraform configuration for that specific submodule. Check other submodules in the repo for examples.
   ```shell
   touch terraform.tf
   ```
4. Make sure you set the required resource tags and state backend for every new submodule you create. See [Resource Tagging](/infrastructure-as-code/resource-tagging) and [Infrastructure State](#infrastructure-state).

## Infrastructure State

!!!warning Warning
Making changes to state configuration, such as changing the bucket, key, or region, is a destructive action and can lead to out-of-sync terraform states. Always consult before making such changes as it would require state migration.
!!!

Terraform uses `.tfstate` files to keep track of the infrastructure state. By default, terraform stores these files locally within the submodule directory, which is insecure as state files can contain sensitive information. We use S3 Buckets to store our infrastructure state remotely. Each AWS account has a single S3 bucket called `k8s-terraform-state-storage-<account-number>` reserved for this purpose.

When creating a new submodule, create a new S3 bucket manually using AWS console and configure the submodule to use its own state file in the S3 bucket by adding a `terraform.backend` block to the _terraform.tf_ file. See other submodules in the repo for examples.

```terraform
terraform {
   backend 's3' {
      bucket       = "k8s-terraform-state-storage-<account-number>"
      key          = "terraform/<account-number>/<submodule-name>.tfstate"
      region       = "us-east-1"
      use_lockfile = false
   }
}
```