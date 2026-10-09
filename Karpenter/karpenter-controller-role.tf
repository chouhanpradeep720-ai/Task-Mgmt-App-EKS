resource "aws_iam_role" "karpenter_controller_role" {

  name = "${var.eks_cluster_name}-karpenter-controller"
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
    Name    = "${var.eks_cluster_name}-karpenter-controller"
    Project = "Task-Mgmt-App"
  }
}

resource "aws_iam_role_policy" "karpenter_controller_policy" {
  name = "${var.eks_cluster_name}-karpenter-controller-policy"
  role = aws_iam_role.karpenter_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ---------------------------------------------------
      # EC2 / SSM / Pricing permissions
      # ---------------------------------------------------

      {
        Sid    = "Karpenter"
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]

        Resource = "*"
      },


      # ---------------------------------------------------
      # Allow Karpenter to terminate only its own nodes
      # ---------------------------------------------------

      {
        Sid    = "ConditionalEC2Termination"
        Effect = "Allow"

        Action = [
          "ec2:TerminateInstances"
        ]

        Resource = "*"

        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },


      # ---------------------------------------------------
      # Allow passing the Karpenter Node IAM Role
      # ---------------------------------------------------

      {
        Sid    = "PassNodeIAMRole"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = aws_iam_role.karpenter_node_role.arn
      },


      # ---------------------------------------------------
      # EKS Cluster endpoint lookup
      # ---------------------------------------------------

      {
        Sid    = "EKSClusterEndpointLookup"
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = data.aws_eks_cluster.this.arn
      },


      # ---------------------------------------------------
      # Create Instance Profile
      # ---------------------------------------------------

      {
        Sid    = "AllowScopedInstanceProfileCreationActions"
        Effect = "Allow"

        Action = [
          "iam:CreateInstanceProfile"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"                 = var.aws_region
          }

          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },


      # ---------------------------------------------------
      # Tag Instance Profile
      # ---------------------------------------------------

      {
        Sid    = "AllowScopedInstanceProfileTagActions"
        Effect = "Allow"

        Action = [
          "iam:TagInstanceProfile"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"                 = var.aws_region

            "aws:RequestTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region"                 = var.aws_region
          }

          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"

            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },


      # ---------------------------------------------------
      # Instance Profile management
      # ---------------------------------------------------

      {
        Sid    = "AllowScopedInstanceProfileActions"
        Effect = "Allow"

        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"                 = var.aws_region
          }

          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },


      # ---------------------------------------------------
      # Read Instance Profile
      # ---------------------------------------------------

      {
        Sid    = "AllowInstanceProfileReadActions"
        Effect = "Allow"

        Action = [
          "iam:GetInstanceProfile"
        ]

        Resource = "*"
      },


      # ---------------------------------------------------
      # List Instance Profiles
      # ---------------------------------------------------

      {
        Sid    = "AllowUnscopedInstanceProfileListAction"
        Effect = "Allow"

        Action = [
          "iam:ListInstanceProfiles"
        ]

        Resource = "*"
      }
    ]
  })
}

# This resource creates an association between the Karpenter controller's IAM role and the Karpenter service account in the EKS cluster, 
# allowing the controller to assume the role and perform actions on behalf of the service account.
resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.eks_cluster_name
  namespace       = "karpenter"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller_role.arn

}
