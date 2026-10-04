resource "aws_eks_addon" "vpc_cni" {
  cluster_name = module.eks-cluster.cluster_name
  addon_name   = "vpc-cni"

}

# KUBE-PROXY

resource "aws_eks_addon" "coredns" {

  cluster_name = module.eks-cluster.cluster_name

  addon_name = "coredns"
  depends_on = [
    module.eks-cluster
  ]
}

# KUBE-PROXY

resource "aws_eks_addon" "kube_proxy" {

  cluster_name = module.eks-cluster.cluster_name

  addon_name = "kube-proxy"
}

# EBS CSI DRIVER
# Kubernetes persistent storage ke liye.

resource "aws_eks_addon" "ebs_csi_driver" {

  cluster_name = module.eks-cluster.cluster_name

  addon_name = "aws-ebs-csi-driver"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver,
    aws_eks_pod_identity_association.ebs_csi_driver
  ]
}

# EKS POD IDENTITY AGENT
# Pods ko AWS IAM permissions dene ke liye.

resource "aws_eks_addon" "pod_identity_agent" {

  cluster_name = module.eks-cluster.cluster_name

  addon_name = "eks-pod-identity-agent"
}
