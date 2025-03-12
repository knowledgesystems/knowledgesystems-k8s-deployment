---
icon: home
---
# CDSI K8s Documentation
Welcome to the documentation site for the **Knowledge Systems Apps** in CDSI at MSK. This site serves as the central resource for understanding, managing, and deploying the infrastructure and applications in the [K8s repository](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment).

## Repo Structure
To eliminate the inconsistent directory structure in our repo, we are in the process of refactoring the directories. The goal is to group Infrastructure as Code (IaC) and ArgoCD-base GitOps configurations into dedicated folders:
- **`iac/`** → Infrastructure as Code (Terraform, AWS, EKS)
  - **`aws/`** → Cloud provider
    - **`<account-number/>`** → Terraform modules specific to each account
      - **`clusters/`**
        - **`<cluster-name>/`**
          - **`<resource-type>/`** → Resource type, e.g. _eks_ or _s3_ for AWS.
            - **`main.tf`**
            - **`terraform.tf`**
            - **`variables.tf`**
      - **`shared/`** → Terraform modules for resources that live outside of a cluster.
        - **`<resource-type>/`** → Resource type, e.g. _eks_ or _s3_ for AWS.
          - **`main.tf`**
          - **`terraform.tf`**
          - **`variables.tf`**
- **`argocd/`** → GitOps configurations for Kubernetes applications
  - **`<account-number/>`** → Deployment files specific to each account
    - **`clusters/`**
      - **`<cluster-name>/`**
        - **`apps/`**
          - **`argocd/`** → App-of-apps configuration for ArgoCD
            - **`app-1.yaml`** → Config file for App-1
            - **`app-2.yaml`** → Config file for App-2
          - **`app-1/`** → Deployment files for App-1
          - **`app-2/`** → Deployment files for App-2

As part of this restructuring, the repository will transition to a **clearer folder structure** where all infrastructure-related code is in `iac/`, and all ArgoCD application configurations are in `argocd/`. This will improve maintainability and make it easier to onboard new contributors.

## Contact

If you are working on this repo and need help, reach out to us.

:icon-mark-github: **Github:** [knowledgesystems-k8s-deployment](https://github.com/knowledgesystems/knowledgesystems-k8s-deployment)