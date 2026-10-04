module "eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name = var.eks_cluster_name

  kubernetes_version = var.eks_version

  vpc_id = module.eks_vpc.vpc_id

  subnet_ids = module.eks_vpc.private_subnets

  # EKS API ENDPOINT

  endpoint_private_access = true
  endpoint_public_access  = true


  # Initial learning setup.
  # Later restrict this to your own public IP.
  endpoint_public_access_cidrs = [
    "0.0.0.0/0"
  ]

  enable_cluster_creator_admin_permissions = true

  tags = {
    Name = var.eks_cluster_name
  }

}
