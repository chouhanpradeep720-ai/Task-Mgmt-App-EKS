# EKS

output "eks_cluster_name" {
  description = "EKS cluster name"

  value = module.eks-cluster.cluster_name
}

output "eks_cluster_endpoint" {

  description = "EKS API endpoint"

  value = module.eks-cluster.cluster_endpoint
}

output "eks_cluster_version" {

  description = "EKS Kubernetes version"

  value = module.eks-cluster.cluster_version
}

#VPC 

output "eks_vpc_id" {

  description = "EKS VPC ID"

  value = module.eks_vpc.vpc_id
}


output "access_vpc_id" {

  description = "Access VPC ID"

  value = module.access_vpc.vpc_id
}

# SUBNET


output "eks_public_subnets" {

  description = "EKS public subnets"

  value = module.eks_vpc.public_subnets
}


output "eks_private_subnets" {

  description = "EKS private subnets"

  value = module.eks_vpc.private_subnets
}


output "access_public_subnets" {

  description = "Access VPC public subnets"

  value = module.access_vpc.public_subnets
}

output "access_private_subnets" {

  description = "Access VPC public subnets"

  value = module.access_vpc.private_subnets
}

# PEERING

output "vpc_peering_id" {

  description = "VPC peering connection ID"

  value = aws_vpc_peering_connection.eks_to_access.id
}

# NODE GROUP

output "node_group_name" {

  description = "EKS managed node group"

  value = aws_eks_node_group.task_app_nodes.node_group_name
}
