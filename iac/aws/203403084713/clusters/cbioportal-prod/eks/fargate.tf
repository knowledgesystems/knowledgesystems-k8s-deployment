locals {
  cluster_name = basename(module.eks_cluster.cluster_arn)
}

# Fargate profile
resource "aws_eks_fargate_profile" "cbioportal-dev" {
  cluster_name           = local.cluster_name
  fargate_profile_name   = "cbioportal-dev"
  pod_execution_role_arn = module.iam.fargate_pod_execution_role_arn
  subnet_ids             = var.SUBNET_IDS

  selector {
    namespace = var.FARGATE_SELECTOR_NAMESPACE
    labels    = var.FARGATE_SELECTOR_LABELS
  }
}