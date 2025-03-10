# Argo CD

The `argocd` directory in the repo contains all our manifests for managing the kubernetes deployments across multiple AWS accounts and clusters. We follow the _app-of-apps_ workflow to manage everything. Each `argocd/aws/<account-number>/clusters/<cluster-name>/apps` directory has a `argocd` subdirectory that contains the parent app. This parent app is responsible for managing all other apps in ArgoCD within that cluster. See [repo structure](/#repo-structure) for details.

## Syncing Changes
The `argocd` directory contains manifests organized by `aws-account/cluster-name/app-name`. After making changes to manifests, push your changes to the repo. Once your changes are merged into the `master` branch, you can use the Argo CD dashboard to sync and deploy your changes.

## Accessing the Argo CD Dashboard
Argo CD dashboard can be accessed in multiple ways.

### Public Instance
For some of our clusters, we have attached the Argo CD dashboard to a public domain. See table below for the list of apps that have Argo CD instances publicly available.

{.compact}
| App        | Argo CD URL                                            |
|------------|--------------------------------------------------------|
| cBioPortal | [argocd.cbioportal.org](https://argocd.cbioportal.org) |

### Port-Forwarding
By default, all ArgoCD installations come with a built-in dashboard that you can access by port-forwarding. You will need `kubectl` and access to the cluster for this method.
1. Confirm kubectl is using the correct context. E.g. if you want to work on the `my-cluster` cluster under account `123456789abc`, your output should be:
   ```shell
   kubectl config current-context
   # Output: arn:aws:eks:us-east-1:123456789abc:cluster/my-cluster
   ```
2. Port-forward ArgoCD dashboard from the cluster to your [localhost:8080](localhost:8080).
   ```shell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
3. Open ArgoCD at [localhost:8080](localhost:8080) and login with your credentials.

## Creating New Apps
Follow the steps below to add a new app to ArgoCD.
1. Create a new subdirectory under the appropriate nesting structure `argocd/aws/<account-number>/clusters/<cluster-name>/apps/<app-name>`. This subdirectory will host your deployment files.
2. In the `argocd` subdirectory under the same nesting level, add a new `Application` manifest. Look at other apps in the repo for examples.
3. Commit your changes. ArgoCD will automatically sync the changes and the new app should show up in the Dashboard.

## Creating New Kubernetes Objects
Follow the steps below to create new Kubernetes objects in a cluster (e.g. Deployment).
1. Add a new manifest file under the appropriate nesting structure `argocd/aws/<account-number>/clusters/<cluster-name>/apps/<app-name>/object-name.yaml`.
2. Push your changes to the repo.
3. Launch ArgoCD dashboard and refresh the app to fetch new changes from the repo.
4. Sync changes.