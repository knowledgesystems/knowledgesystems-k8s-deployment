# Karpenter NodePool: airflow-importer-dag

This directory holds the Karpenter `NodePool` and `EC2NodeClass` that provision a dedicated,
autoscaling pool for the `import_public_hackathon` Airflow DAG. Synced by the `iac` Argo
Application (`../argocd/iac.yaml`).

## What it does

- `node-pools.yaml` — `NodePool airflow-importer-dag`: on-demand `m5.2xlarge` nodes labeled and tainted
  `workload=airflow-importer-dag`, capped at a single node (`limits.cpu: "8"`), consolidated to zero
  ~2m after the last pod exits.
- `ec2-classes.yaml` — `EC2NodeClass airflow-importer-dag`: Bottlerocket x86, discovers its subnet and
  security group by the `karpenter.sh/discovery=cbioportal-prod` tag, uses the
  `userServiceRole-KarpenterNode` instance profile.

Only `import_public_hackathon`'s task pods tolerate `workload=airflow-importer-dag` and nodeSelect it
(set in `cmo-pipelines/dags/import_public_hackathon.py`), so nothing else lands here. Every other DAG
stays on the static `workload=airflow` managed node group.

## Install decision: mirror the Public cluster

The Karpenter **controller** is installed via Terraform in
`iac/aws/666628074417/clusters/cbioportal-prod/eks/main.tf` using
`terraform-aws-modules/eks//modules/karpenter@v21.9.0` + a `helm_release`, wired **exactly the same
way as the cbioportal-prod Public cluster** (account `203403084713`): the Karpenter module, the Helm
release, and the `helm` provider all read their cluster facts from the `module "eks_cluster"`
outputs, and the node security group is tagged via the module's `node_security_group_tags` input.

Karpenter is proven compatible with a custom MSK-Staging EKS kit on the Public cluster, so we assume
the same holds for this cluster's kit (`terraform-aws-hyc-eks@4.0.0`) and mirror that integration.

The exact module outputs/inputs this depends on — and a caveat that the two kits don't use identical
output names — are documented in
[`iac/aws/666628074417/clusters/cbioportal-prod/eks/KARPENTER.md`](../../../../../../iac/aws/666628074417/clusters/cbioportal-prod/eks/KARPENTER.md).

A `NodePool`/`EC2NodeClass` here is inert until that controller is running.
