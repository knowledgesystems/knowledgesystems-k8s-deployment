# Best Practices

This page documents infrastructure conventions and practices that help avoid common pitfalls.

## Terraform

!!!danger Use Extreme Caution with Terraform Commands
Terraform can make irreversible changes to live infrastructure with a single command. Always run `terraform plan` before `terraform apply` and carefully review every proposed change. If you don't understand a change or something looks unexpected, stop and ask before proceeding. A misunderstood plan can destroy or recreate critical resources.
!!!

### Secrets Management
Use Terraform only to **create** the AWS Secrets Manager resource (or SSM parameter). Never set the secret value through Terraform — doing so would persist the plaintext value in the `.tfstate` file. After Terraform creates the resource, set the value manually using the AWS CLI.

## IAM

Every IAM role and policy we create — via Terraform or the console — must:

1. Have a name prefixed with `user`.
2. Have the `AutomationOrUserServiceRolePermissions` permissions boundary attached (roles only; policies just need the prefix).

Creating a role that violates either rule fails with `AccessDenied`.

The naming convention in use is `userServiceRole<Purpose>` for roles and `userServicePolicy<Purpose>` for policies, e.g. `userServiceRoleCellxgeneS3Mountpoint`.

Terraform is the preferred way to create these. Use the console only for one-offs, and port them back to Terraform when you can.

### Terraform

```hcl
resource "aws_iam_role" "userServiceRoleExample" {
  name                 = "userServiceRoleExample"
  permissions_boundary = "arn:aws:iam::${local.account_id}:policy/AutomationOrUserServiceRolePermissions"

  # ...
}
```

### AWS Console

To create a role:

1. **IAM → Roles → Create role**, then pick the trusted entity as usual.
2. On the **Add permissions** step, expand **Set permissions boundary** and choose *Use a permissions boundary to control the maximum role permissions*.
3. Select `AutomationOrUserServiceRolePermissions` from the policy list.
4. On the final step, set **Role name** to `userServiceRole<Purpose>` and create.

To create a policy, go to **IAM → Policies → Create policy** and name it `userServicePolicy<Purpose>`. No boundary is needed.

The boundary cannot be added after the fact through the create flow — if you miss step 2, open the role and use **Permissions boundary → Set permissions boundary**.

## Compute

### Prefer Managed Node Groups Over Standalone EC2 Instances
Avoid spinning up standalone EC2 instances. Instead, use a managed node group within an EKS cluster. Node groups are easier to scale, patch, and maintain, and they integrate with Kubernetes scheduling and lifecycle management out of the box.

### Prefer Spot Instances for Non-Critical Workloads
For development services or experimental workloads, use **Spot** capacity instead of On-Demand. Spot instances offer significant cost savings and are acceptable where brief downtime is tolerable.

## Storage

### Prefer EFS Over PVCs
Use EFS (Elastic File System) for persistent storage rather than EBS-backed PersistentVolumeClaims. PVCs are tied to a single Availability Zone, which means:

- They cannot be reused across AZs.
- Cluster upgrades that move workloads between AZs require recreating the PVC.
- Migrating data between AZs requires manual cloning or dump/restore.

If a PVC must be used, ensure the data stored on it is **discardable** — treat it as ephemeral storage that can be recreated from source rather than relied upon as durable state.
