# Genome Nexus

## MongoDB Volume Management
Genome Nexus MongoDB databases are backed by AWS EBS volumes that are managed independently of the Helm chart. This decoupling improves disaster recovery and ensures the underlying data persists safely across pod restarts, rolling upgrades, and node replacements.

### How It's Set Up
1. EBS volumes are provisioned via Terraform and are defined in the ec2 sub-module of the cluster:
    ```
    iac/aws/203403084713/clusters/cbioportal-prod/ec2/main.tf
    ```
   Each volume resource specifies the availability zone, size, type, and tags. All volumes have `prevent_destroy = true` to guard against accidental deletion. Note: the ec2 module is a sub-module and must be applied via the eks root module — see the module structure guide [here](../infrastructure-as-code/terraform.md).
2. Each volume is surfaced to Kubernetes via a manually-defined PV and PVC (rather than dynamic provisioning). These are managed in ArgoCD:
    ```
    argocd/aws/203403084713/clusters/cbioportal-prod/apps/genome-nexus-database/pvc/
    ```
   The PV references the EBS volume directly via its `volumeHandle` (the AWS volume ID) and pins scheduling to the correct availability zone via `nodeAffinity`. The `persistentVolumeReclaimPolicy: Retain` ensures the volume is not deleted if the PVC is removed.
3. The MongoDB Helm values set `persistence.existingClaim` to the name of the PVC created above. This tells the chart to use the pre-existing volume rather than provisioning a new one:
    ```yaml
    persistence:
      enabled: true
      existingClaim: gn-mongodb-grch37-v1dot0-pvc
    ```
    The `nodeSelector` in the Helm values must also match the availability zone of the underlying EBS volume, since EBS volumes are AZ-scoped.

### Cloning a Database Volume
Sometimes you may need to clone a database (e.g., to seed a new environment or test a migration). The process uses an EBS snapshot as an intermediate step.

#### Step 1: Snapshot the source volume
In the AWS console, create a snapshot of the EBS volume you want to clone. No Terraform changes are needed for this step. Wait for the snapshot to reach the completed state before proceeding.

#### Step 2: Create a new volume from the snapshot
Add a new aws_ebs_volume resource using Terraform. Set snapshot_id to the ID of the snapshot from Step 1. The size must be greater than or equal to the size of the source volume. For example:

```terraform
resource "aws_ebs_volume" "gn-mongo-v1dot0-mongodb-clone" {
    availability_zone = var.GENOMENEXUS_EBS_VOLUME_AZ
    snapshot_id       = "snap-0xxxxxxxxxxxxxxxxx"
    size              = 300
    type              = "gp3"

     tags = {
       Name = "gn-mongo-v1dot0-mongodb-clone"
       ...
     }
}
```

Apply via the eks root module (make sure you have read the module structure guide before running Terraform for the first time).

#### Step 3: Wire up the new volume
Create a PV and PVC pointing to the new volume ID. Then, before referencing the PVC in a Helm release, be aware that MongoDB will enter recovery mode on first startup. This happens because the snapshot was taken from a live volume that still had file locks from the previous MongoDB instance. Recovery is non-destructive but can take several minutes. To prevent liveness and readiness probes from killing the pod before recovery finishes, temporarily disable them in the Helm values when first deploying:

```yaml
persistence:
  existingClaim: <your-new-pvc-name>

livenessProbe:
  enabled: false
readinessProbe:
  enabled: false
```

Once the pod is running, monitor the logs and wait for a message indicating MongoDB is ready to accept connections. After that, re-enable the probes by removing the `livenessProbe` and `readinessProbe` overrides from the Helm values and resyncing.

#### Step 4: Cleanup
Once the snapshot is no longer needed:

1. Remove the `snapshot_id` field from the Terraform resource block. No need to apply.
2. Delete the snapshot from the AWS console.