resource "aws_vpc_peering_connection" "eks_to_access" {
  vpc_id      = module.eks_vpc.vpc_id
  peer_vpc_id = module.access_vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "task-management-eks-access-peering"
  }
}

# =========================================================
# EKS PRIVATE SUBNETS → ACCESS VPC
# =========================================================

resource "aws_route" "eks_private_to_access" {
  count = length(module.eks_vpc.private_route_table_ids)

  route_table_id            = module.eks_vpc.private_route_table_ids[count.index]
  destination_cidr_block    = var.access_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eks_to_access.id
}


# =========================================================
# ACCESS PUBLIC SUBNETS → EKS VPC
# =========================================================

resource "aws_route" "access_public_to_eks" {
  count = length(module.access_vpc.public_route_table_ids)

  route_table_id            = module.access_vpc.public_route_table_ids[count.index]
  destination_cidr_block    = var.eks_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eks_to_access.id
}
