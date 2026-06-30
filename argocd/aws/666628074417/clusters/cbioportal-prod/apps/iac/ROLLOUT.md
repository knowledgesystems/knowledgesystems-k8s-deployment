# Rollout order: airflow-importer-dag Karpenter pool

This change moves the `import_public_hackathon` DAG onto a dedicated, autoscaling Karpenter pool
(`workload=airflow-importer-dag`, m5.2xlarge, capped at one node) and then shrinks the shared airflow
node group to 2× m5.large. The steps **must** be applied in the order below.

## Why order matters

The shared-pool shrink and the Karpenter install live in the **same** `main.tf`
(`iac/aws/666628074417/clusters/cbioportal-prod/eks/`). If the shrink is applied before the new pool
and the DAG override are live, there is a window where the `import_public_hackathon` import task
(requests **24Gi**, `-Xmx22g`) has nowhere to run: it won't fit on m5.large (~6.5Gi allocatable), and
its dedicated pool won't exist yet. So the shrink is kept **out** of the Karpenter-install change and
applied last, only after the new pool is proven.

## Steps

### 1. Install Karpenter (Terraform) — non-disruptive
Apply `iac/aws/666628074417/clusters/cbioportal-prod/eks/`. This adds the Karpenter controller,
tags the node SG for discovery, and labels the `addons` node group to host the controller. The
shared `airflow` node group is untouched (stays 3× m5.2xlarge), so nothing reschedules.

Verify: `kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter` → Running.

Prereq to confirm first: the **EKS Pod Identity agent** addon is installed, and the module exposes
the outputs in [`../../../../../../iac/aws/666628074417/clusters/cbioportal-prod/eks/KARPENTER.md`](../../../../../../iac/aws/666628074417/clusters/cbioportal-prod/eks/KARPENTER.md).

### 2. Sync the `iac` Argo Application — pool exists, idle at 0 nodes
Manual-sync the `argocd` app-of-apps to register the `iac` Application, then let it sync the
`NodePool` + `EC2NodeClass` in this directory.

Verify: `kubectl get nodepool,ec2nodeclass` → `airflow-importer-dag` present, no nodes yet.

### 3. Deploy the DAG override + smoke-test
Deploy the `cmo-pipelines` change to `dags/import_public_hackathon.py` (routes its pods to
`workload=airflow-importer-dag`). Trigger `import_public_hackathon` once.

Verify: `kubectl get nodeclaim` and `kubectl get nodes -l workload=airflow-importer-dag -w` → an
m5.2xlarge appears, the task pods land on it (and **not** on the `workload=airflow` nodes), and the
node consolidates away ~2m after the run.

### 4. Shrink the shared airflow node group (Terraform) — LAST, separate apply
Only after step 3 passes. In `eks/main.tf`, the `airflow` block:
- `instance_types`: `["m5.2xlarge"]` → `["m5.large"]`
- `desired_size`/`min_size`/`max_size`: `3`/`1`/`3` → `2`/`2`/`2`
- Leave label/taint `workload=airflow`, subnet pin, block device as-is.

Verify: `kubectl get nodes -l workload=airflow` → 2× m5.large; every non-importer DAG still runs.

Before applying, confirm no other DAG on the shared pool requests >~6Gi — the shared pool also runs
the `cdsi-airflow-dags` gitSync repo. No `cmo-pipelines` DAG does. If any does, keep that pool larger
or give it its own pool.

## Status

Steps 1–3 are staged in the working tree. **Step 4 (the shrink) is intentionally not yet written** —
make it a separate commit/apply once steps 1–3 are verified.
