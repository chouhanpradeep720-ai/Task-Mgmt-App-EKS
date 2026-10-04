resource "aws_eks_node_group" "task_app_nodes" {
  cluster_name    = module.eks-cluster.cluster_name
  node_group_name = "task-app-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  #PRIVATE SUBNET
  subnet_ids = module.eks_vpc.private_subnets

  # INSTANCE

  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  # SCALING

  scaling_config {
    min_size = var.node_min_size

    desired_size = var.node_desired_size

    max_size = var.node_max_size
  }

  # UPDATE
  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = var.environment
    Application = "task-management"
  }

  tags = {
    Name = "task-management-eks-node"
  }
  depends_on = [module.eks-cluster]
}
