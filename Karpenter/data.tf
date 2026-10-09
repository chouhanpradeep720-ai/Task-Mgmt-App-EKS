data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}
# data "aws_subnet" "karpenter" {
#   for_each = toset(var.karpenter_subnet_ids)

#   id = each.value
# }
