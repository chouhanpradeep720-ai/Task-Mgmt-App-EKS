# ---------------------------------------------------------
# Subnet discovery tags
# ---------------------------------------------------------

resource "aws_ec2_tag" "karpenter_subnet_discovery" {

  for_each = toset(var.karpenter_subnet_ids)

  resource_id = each.value

  key   = "karpenter.sh/discovery"
  value = var.eks_cluster_name
}


# ---------------------------------------------------------
# EKS Cluster Security Group discovery tag
# ---------------------------------------------------------

resource "aws_ec2_tag" "karpenter_security_group_discovery" {

  resource_id = data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id

  key   = "karpenter.sh/discovery"
  value = var.eks_cluster_name
}
