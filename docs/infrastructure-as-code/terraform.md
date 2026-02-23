# Terraform
The `iac` directory in the repo contains all Terraform configurations for managing the infrastructure across multiple AWS accounts and clusters.

## Prerequisites
1. **terrafrom**: Install the terraform CLI tool. The recommended way is to use [tfenv](https://github.com/tfutils/tfenv) to install and manage multiple versions of terraform as each cluster runs on a different version.
2. **saml2aws**: Before you can use terraform, you need to make sure you have setup saml2aws and you are logged in to the correct AWS account in your cli. For all of the following commands, terraform uses your awscli to connect to the aws account. Running these commands in the wrong account can lead to destructive actions.

## Module Structure
Before you start working with Terraform, make sure you understand the [repo structure](../README.md) and the module structure. There are two types of terraform modules in this repo, shared modules and cluster specific modules. Shared modules contains services that are shared between clusters (such as s3), and cluster-specific modules contains services that handle resources within a cluster, such as IAM for cluster security groups and roles.

### Shared Modules
Shared modules, such as the S3 module [here](../../iac/aws/203403084713/shared/s3), are self-sufficient standalone modules that can be applied independently.

### Cluster-Specific Modules
Cluster specific modules contain multiple submodules, one of which is the EKS module. The EKS module acts as the root module and is the only one that should be applied directly. The remaining modules are child modules that are imported and managed by the root EKS module - they are not standalone and should never ben applied independently.

The root module will always be the EKS module. Child modules handle supporting concerns like IAM roles or EC2 volumes, and are wired in via module blocks in the root module's main.tf.

#### Example
The cbioportal-prod cluster under AWS account # 203403084713 is configured like this:
```
   iac/aws/203403084713/clusters/cbioportal-prod/
   ├── eks/    # Root module — apply from here
   ├── ec2/    # Sub-module (imported by eks)
   └── iam/    # Sub-module (imported by eks)
```

!!!danger Warning
Only run terraform commands from the root module directory. Running them from a child module directory is unsupported and may produce incomplete or incorrect infrastructure state.
!!!

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
2. Make sure your CLI is using the correct version of terraform that is mentioned in the `terraform.tf` file.
   ```shell
   tfenv use <terraform-version>
   ```
3. Now you can make changes to the Terraform files. After making changes format them to ensure consistent formatting.
   ```shell
   terraform fmt
   ```
4. Initialize terraform submodule. This creates intermediate lock and state files.
   ```shell
   terraform init
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
1. Create a submodule directory under the appropriate nesting structure. The nesting structure would depend on the service and whether that service is specific to each cluster or shared between them.
   ```shell
   # For a cluster-specific service, such as IAM roles attached to a cluster. 
   mkdir -p iac/aws/<account-number>/clusters/<cluster-name>/iam
   
   # For a service shared between clusters, such as S3.
   mkdir -p iac/aws/<account-number>/shared/s3
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

!!!danger Warning
Making changes to state configuration, such as changing the bucket, key, or region, is a destructive action and can lead to out-of-sync terraform states. Always consult before making such changes as it would require state migration.
!!!

Terraform uses `.tfstate` files to keep track of the infrastructure state. By default, terraform stores these files locally within the submodule directory, which is insecure as state files can contain sensitive information. We use S3 Buckets to store our infrastructure state remotely. Each AWS account has a single S3 bucket called `k8s-terraform-state-storage-<account-number>` reserved for this purpose.

When creating a new submodule, create a new S3 bucket manually using AWS console and configure the submodule to use its own state file in the S3 bucket by adding a `terraform.backend` block to the _terraform.tf_ file. See other submodules in the repo for examples.

!!!info Backend Key Should Be Unique
When defining the backend block as shown below, make sure that the `key` is unique within that bucket.
!!!

```terraform
terraform {
   backend 's3' {
      bucket       = "k8s-terraform-state-storage-<account-number>"
      key          = "terraform/<account-number>/<submodule-name>.tfstate" # Should be unique within the bucket
      region       = "us-east-1"
      use_lockfile = false
   }
}
```