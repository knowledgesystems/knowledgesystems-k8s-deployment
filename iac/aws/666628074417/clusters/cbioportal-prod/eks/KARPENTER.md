# Karpenter integration — requirements for the EKS module

The Karpenter controller here is wired the same way as the cbioportal-prod **Public** cluster
(account `203403084713`): the `module "karpenter"`, the `helm_release "karpenter"`, and the `helm`
provider all read their cluster facts from the **`module "eks_cluster"`** outputs, rather than
looking them up from AWS. This mirrors the proven Public setup.

Because of that, the EKS module (`MSK-Staging/terraform-aws-hyc-eks@4.0.0`) **must expose the
following contract**. If `terraform plan` fails with "Unsupported attribute" / "Unsupported
argument," it is naming a connector below that the module doesn't provide under that name.

## Required module OUTPUTS

| Output | Consumed by |
|---|---|
| `cluster_name` | `module.karpenter.cluster_name`; `helm_release` settings; `helm` provider `exec` |
| `cluster_endpoint` | `helm_release` `settings.clusterEndpoint`; `helm` provider `host` |
| `cluster_certificate_authority_data` | `helm` provider `cluster_ca_certificate` |
| `oidc_provider` | `module.iam` (pre-existing) |
| `cluster_arn` | `module.iam` (pre-existing) |

## Required module INPUTS

| Input | Purpose |
|---|---|
| `node_security_group_tags` | Tags the node security group with `karpenter.sh/discovery=<cluster>` so the `EC2NodeClass` can discover it |

## ⚠ Known naming caveat — verify the `cluster_*` outputs

The two clusters' in-house kits are **different repos and do not use identical output names.** Proof:
this cluster's `module.iam` already reads `module.eks_cluster.oidc_provider`, whereas Public reads
`module.eks_cluster.cluster_oidc_provider` for the same thing.

So the `cluster_name` / `cluster_endpoint` / `cluster_certificate_authority_data` references added for
Karpenter are **assumed** to exist in `terraform-aws-hyc-eks@4.0.0` (per the decision to mirror
Public). Confirm them with a `terraform plan`, or by checking the module's `outputs.tf`. If any is
named differently, update the reference in `main.tf` / `terraform.tf` to the kit's actual output name
— the wiring is otherwise unchanged.

## Cluster-level requirement (not a module output)

- **EKS Pod Identity agent addon** must be installed on the cluster. The Karpenter module
  (`terraform-aws-modules/eks//modules/karpenter@v21.9.0`) grants the controller its IAM permissions
  via EKS Pod Identity; without the `eks-pod-identity-agent` addon the controller cannot authenticate.
