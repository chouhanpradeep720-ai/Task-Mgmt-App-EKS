module "eks_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "task-management-eks-vpc"
  cidr = var.eks_vpc_cidr
  azs  = local.azs

  # PUBLIC SUBNETS
  public_subnets = var.eks_public_subnets

  # PRIVATE SUBNETS
  private_subnets = var.eks_private_subnets

  # NAT GATEWAY 
  enable_nat_gateway = true

  # One NAT Gateway initially to reduce cost.
  single_nat_gateway = true

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Name                     = "task-management-public-subnet"
    Environment              = var.environment
    Project                  = "task-management"
    "kubernetes.io/role/elb" = "1"

    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  private_subnet_tags = {
    Name                              = "task-management-private-subnet"
    Environment                       = var.environment
    Project                           = "task-management"
    "kubernetes.io/role/internal-elb" = "1"

    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "karpenter.sh/discovery"                        = var.eks_cluster_name
  }
  tags = {
    Name = "task-management-eks-vpc"
  }
}


