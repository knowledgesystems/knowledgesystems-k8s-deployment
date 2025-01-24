# Kubernetes deployment of Knowledge Systems Apps
This repo contains all the kubernetes configuration files needed to run the Knowledge System Group Apps on Kubernetes. For a schematic overview see:

https://docs.google.com/presentation/d/1mnSnSZRDJmX0vv8ZF_lNQvX2sz73deKia8w5S9YciR8/

## Create Kubernetes cluster on Amazon using Kops
We are working on integrating Terraform. See [IAC with Terraform](#iac-with-terraform-work-in-progress) and contact [Zain](mailto:nasirz1@mskccc.org) if you need help setting up a new cluster.

## Initialize the Kubernetes cluster
### Helm Package Manager
We use [helm](https://github.com/kubernetes/helm) to deploy several services.
Set up helm with Role-based access control:

https://github.com/kubernetes/helm/blob/master/docs/rbac.md#role-based-access-control

## Knowledge Systems Group Apps
- [cBioPortal](public-eks/cbioportal-prod/README.md)
- [Genome Nexus](genome-nexus/README.md)
- [OncoKB](oncokb/README.md)



## Routing of Domain Names
We use nginx ingress to handle the routing to the services. See
[ingress/README.md](ingress/README.md).

## Monitoring
We use Prometheus for monitoring our apps, and Grafana to visualize.
- We use the kube-prometheus-stack to install prometheus and grafana
- We are sticking to helm chart `prometheus-community/kube-prometheus-stack --version 46.8.0--set grafana.adminPassword=<pass>`

## IAC with Terraform (Work in Progress)
The [iac](/iac) directory contains all Terraform configurations for managing the infrastructure across multiple AWS accounts and clusters.

### Prerequisites
1. **saml2aws**: Before you can use terraform, you need to make sure you have setup saml2aws and you are logged in to the correct AWS account in your cli. For all of the following commands, terraform uses your awscli to connect to the aws account. Running these commands in the wrong account can lead to destructive actions.

### Usage
The [iac](/iac) directory contains multiple submodules where each submodule resides under varying nesting levels. Essentially, any subdirectory that has `*.tf` files is a submodule. We don't manage a root module config to avoid accidental disastrous actions and changes that end up impacting multiple accounts at the same time. To make changes to each module, change your present working directory to that module where the `*.tf` files reside.
1. Change directory into the appropriate module. E.g., Do the following if you want to work on the EKS setup under the `cbioportal-prod` cluster in account `666628074417`.
   ```shell
   cd iac/aws/666628074417/clusters/cbioportal-prod/eks
   ```
2. Pull remote module sources. This requires Git authentication when running for the first time.
   ```shell
   terraform get
   ```
3. Now you can make changes to the Terraform files. After making changes format them to ensure consistent formatting.
   ```shell
   terraform fmt
   ```
3. Initialize terraform submodule. This creates intermediate lock and state files.
   ```shell
   terraform init
   ```
4. Validate your terraform files.
   ```shell
   terraform validate
   ```
4. Dry run to see what changes you are making.
   ```shell
   terraform plan
   ```
5. Apply changes.
   ```shell
   terraform apply
   ```
   
### Infrastructure State

> ### ⚠️ **WARNING**
> Making changes to state configuration, such as changing the bucket, key, or region, is a destructive action and can lead to out-of-sync terraform states. Always consult before making such changes as it would require state migration.

Terraform uses `.tfstate` files to keep track of the infrastructure state. By default, terraform stores these files locally within the module subdirectory, which is insecure as state files can contain sensitive information. We use S3 Buckets and DynamoDB tables to store our infrastructure state remotely. Each AWS account has a single S3 bucket and a single DynamoDB table, both called `k8s-terraform-state-storage`, reserved for this purpose.

When creating a new submodule, configure it to use its own state file in the S3 bucket by adding a `backend` block to the _terraform.tf_ file. Check [example](iac/aws/666628074417/clusters/cbioportal-prod/eks/terraform.tf).

```terraform
backend "s3" {
   bucket = "k8s-terraform-state-storage"
   key = "terraform/<path>/<to>/<submodule>/eks.tfstate"
   region = "us-east-1"
}
```