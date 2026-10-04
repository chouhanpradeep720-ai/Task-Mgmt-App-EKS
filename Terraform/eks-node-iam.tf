# EKS NODE I AM ROLE

resource "aws_iam_role" "eks_node_role" {
  name = "${var.eks_cluster_name}-node-role"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"

      Statement = [
        {
          Effect = "Allow"

          Principal = {
            Service = "ec2.amazonaws.com"
          }

          Action = "sts:AssumeRole"
        }
      ]
  })
  tags = {
    Name = "${var.eks_cluster_name}-node-role"
  }
}

# EKS WORKER NODE POLICY

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role = aws_iam_role.eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# ECR READ ONLY

resource "aws_iam_role_policy_attachment" "ecr_read_only" {

  role = aws_iam_role.eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# VPC CNI

resource "aws_iam_role_policy_attachment" "cni_policy" {

  role = aws_iam_role.eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


# ==========================================
# EBS CSI DRIVER IAM ROLE
# ==========================================

resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.eks_cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.eks_cluster_name}-ebs-csi-driver-role"
  }
}


# ==========================================
# EBS CSI DRIVER AWS PERMISSIONS
# ==========================================

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role = aws_iam_role.ebs_csi_driver.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}


# ==========================================
# EKS POD IDENTITY ASSOCIATION
# ==========================================

resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name = module.eks-cluster.cluster_name

  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"

  role_arn = aws_iam_role.ebs_csi_driver.arn
}
