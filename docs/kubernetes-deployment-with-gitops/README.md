---
icon: rocket
---
# Kubernetes Deployment with GitOps
We are gradually moving towards an [Argo CD](https://argo-cd.readthedocs.io/en/stable/) managed Kubernetes workflow. The goal is to have all manifests for managing applications across multiple AWS accounts and clusters within the `argocd` directory in the repo.

## ArgoCD
To eliminate syncing issues and ensure better management of our Kubernetes deployment, we use Argo CD. The K8s repo is used as the single source of truth for our deployments. We also follow the **App-of-Apps** pattern to structure our deployments, where a **parent argocd application** is responsible for managing all other apps within a cluster. The [repo structure](/#repo-structure) is setup to mirror follow this principle. See [Argo CD](/kubernetes-deployment-with-gitops/argocd) for further details.