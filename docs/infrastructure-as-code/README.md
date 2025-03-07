---
icon: cloud
---
# Infrastructure as Code (IaC)
We are gradually adopting [Terraform](https://www.terraform.io/) as our primary Infrastructure as Code (IAC) tool to provision and manage cloud resources in a scalable and consistent manner. While some infrastructure is still managed manually or through other tools, we are actively migrating towards a fully Terraform-driven approach. Our goal is to standardize infrastructure management by leveraging Git as the source of truth.

## Terraform
To improve resource tracking and management, we use Terraform to provision resources in AWS. The [repo structure](/#repo-structure) is setup to mirror this AWS setup and uses submodules to organize resources across multiple accounts. See [Terraform](/infrastructure-as-code/terraform/) for documentation on how to set up and manage Terraform.

## Resource Tagging
Proper tagging of all cloud resources provisioned through Terraform is required. This enables better resource tracking, accountability, cost analysis. There is a set of tags that should be attached to all existing and new resources. See [Resource Tagging](/infrastructure-as-code/resource-tagging) for further details.

## Cost Analysis
All the above efforts are eventually only useful if we closely monitor cloud costs. There are multiple ways to do this, including [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/) and [CloudHealth](https://apps.cloudhealthtech.com). See [Cost Analysis] for further details.

## IAC with Terraform (Work in Progress)
The [iac](/iac) directory contains all Terraform configurations for managing the infrastructure across multiple AWS accounts and clusters.

### Prerequisites
1. **saml2aws**: Before you can use terraform, you need to make sure you have setup saml2aws and you are logged in to the correct AWS account in your cli. For all of the following commands, terraform uses your awscli to connect to the aws account. Running these commands in the wrong account can lead to destructive actions.

### AWS Cli Setup
By default, submodules in this repo use the `default` aws cli profile when running commands. To use a custom profile, set the `TF_VAR_AWS_PROFILE` environment variable.
```shell
export TF_VAR_AWS_PROFILE=<profile-name>
```

### Usage
The [iac](/iac) directory contains multiple submodules where each submodule resides under varying nesting levels. Essentially, any subdirectory that has `*.tf` files is a submodule. We don't manage a root module config to avoid accidental disastrous actions and changes that end up impacting multiple accounts at the same time. To make changes to each module, change your present working directory to that module where the `*.tf` files reside.
1. Change directory into the appropriate module. E.g., Do the following if you want to work on the EKS setup under the `cbioportal-prod` cluster in account `666628074417`.
   ```shell
   cd iac/aws/666628074417/clusters/cbioportal-prod/eks
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

### Creating New Submodule
Follow the steps below to create a new submodule.
1. Create a submodule directory under the appropriate nesting structure.
   ```shell
   mkdir -p iac/aws/<account-number>/clusters/<cluster-name>/<submodule-name>
   
   # E.g. For a s3 submodule, you would do this
   # mkdir -p iac/aws/203403084713/clusters/cbioportal-prod/s3
   ```
2. Move into the new module.
   ```shell
   cd iac/aws/<account-number>/clusters/<cluster-name>/<submodule-name>
   ```
3. Create a `terraform.tf` file for the terraform configuration for that specific submodule. Check other submodules in this repo for examples.
   ```shell
   touch terraform.tf
   ```
4. Make sure you set the required resource tags and state backend for every new submodule you create. See [Resource Tagging](#resource-tagging) and [Infrastructure State](#infrastructure-state).

### Resource Tagging
Tagging all submodule is very important for tracking our AWS costs. All PRs are checked by a linting Github Action to make sure proper tags have been added to each submodule. PRs are blocked in case of failure. When creating a new submodule or managing existing ones, make sure that the `terraform.tf` file contains the following tags within the `provider "aws"` block. Check existing submodules for examples.
```yaml
provider "aws" {
  ...
  default_tags {
    tags = {
      CDSI-Owner = <team-owner-email>
      CDSI-Team  = <team-name>
      CDSI-App   = <app-name>
    }
  }
  ...
}
```

### Infrastructure State

> ### ⚠️ **WARNING**
> Making changes to state configuration, such as changing the bucket, key, or region, is a destructive action and can lead to out-of-sync terraform states. Always consult before making such changes as it would require state migration.

Terraform uses `.tfstate` files to keep track of the infrastructure state. By default, terraform stores these files locally within the module subdirectory, which is insecure as state files can contain sensitive information. We use S3 Buckets to store our infrastructure state remotely. Each AWS account has a single S3 bucket called `k8s-terraform-state-storage-<account-number>` reserved for this purpose.

When creating a new submodule, configure it to use its own state file in the S3 bucket by adding a `backend` block to the _terraform.tf_ file. Check [example](iac/aws/666628074417/clusters/cbioportal-prod/eks/terraform.tf).

```terraform
backend "s3" {
   bucket       = "k8s-terraform-state-storage-<account-number>"
   key          = "terraform/<account-number>/eks.tfstate"
   region       = "us-east-1"
   use_lockfile = false
}
```