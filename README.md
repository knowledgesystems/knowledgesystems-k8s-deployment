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

## ArgoCD (Work in Progress)
The [argocd](/argocd) directory contains all our manifests for managing the kubernetes deployments across multiple AWS accounts and clusters. We follow the _app-of-apps_ workflow to manage everything. Each `argocd/aws/<account-number>/clusters/<cluster-name>/apps` directory has a `argocd` subdirectory that contains the parent app. This parent app is responsible for managing all other apps in ArgoCD within that cluster.

### Prerequisites
1. **kubectl**: Before you can use ArgoCD to manage deployments, make sure you have access to the cluster where ArgoCD is deployed on and your local kubectl config is set up to use the correct context.

### Accessing the Dashboard
The [argocd](/argocd) directory contains manifests organized by aws-account/cluster-name/app-name. After making changes to manifests, following the steps below to launch the ArgoCD dashboard locally and sync your changes.
1. Confirm kubectl is using the correct context. E.g. if you want to work on the `cbioportal-prod` cluster under account `666628074417`, your output should be:
   ```shell
   kubectl config current-context
   # Output: arn:aws:eks:us-east-1:666628074417:cluster/cbioportal-prod-<random-number>
   ```
2. Port-forward ArgoCD dashboard from the cluster to your [localhost:8080](localhost:8080).
   ```shell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
3. Open ArgoCD at [localhost:8080](localhost:8080) and login with admin credentials. For credentials, [email us](mailto:nasirz1@mskcc.org).

### Creating New Apps
Follow the steps below to add a new app to ArgoCD.
1. Create a new subdirectory under the appropriate nesting structure `argocd/aws/<account-number>/clusters/<cluster-name>/apps/<app-name>`. This subdirectory will host your deployment files.
2. In the `argocd` subdirectory under the same nesting level, add a new `Application` manifest. Look at other apps in this repo for example.
3. Commit your changes. ArgoCD will automatically sync the changes and the new app should show up in the Dashboard.

### Creating New Kubernetes Objects
Follow the steps below to create new Kubernetes objects in a cluster (e.g. Deployment).
1. Add a new manifest file under the appropriate nesting structure `argocd/aws/<account-number>/clusters/<cluster-name>/apps/<app-name>/object-name.yaml`.
2. Push your changes to the repo.
3. Launch ArgoCD dashboard and refresh the app to fetch new changes from the repo.
4. Sync changes.

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