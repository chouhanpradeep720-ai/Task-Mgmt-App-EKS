output "cluster_name" {
  value = var.eks_cluster_name
}

output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller_role.arn
}

output "karpenter_node_role_arn" {
  value = aws_iam_role.karpenter_node_role.arn
}

output "karpenter_namespace" {
  value = var.karpenter_namespace
}

output "karpenter_version" {
  value = var.karpenter_version
}
