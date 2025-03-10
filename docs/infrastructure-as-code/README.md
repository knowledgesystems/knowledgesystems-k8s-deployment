---
icon: cloud
---
# Infrastructure as Code (IaC)
We are gradually adopting [Terraform](https://www.terraform.io/) as our primary Infrastructure as Code (IAC) tool to provision and manage cloud resources in a scalable and consistent manner. While some infrastructure is still managed manually or through other tools, we are actively migrating towards a fully Terraform-driven approach. Our goal is to standardize infrastructure management by leveraging Git as the source of truth.

## Terraform
To improve resource tracking and management, we use Terraform to provision resources in AWS. The [repo structure](/#repo-structure) is setup to mirror this AWS setup and uses submodules to organize resources across multiple accounts. See [Terraform](/infrastructure-as-code/terraform/) for documentation on how to set up and manage Terraform.

## Resource Tagging
Proper tagging of all cloud resources provisioned through Terraform is required. This enables better resource tracking, accountability, cost analysis. There is a set of tags that should be attached to all existing and new resources. See [Resource Tagging](/infrastructure-as-code/resource-tagging) for further details.