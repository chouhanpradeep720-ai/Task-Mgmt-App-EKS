resource "kubernetes_manifest" "karpenter_nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"

    metadata = {
      name = "default"
    }

    spec = {
      role = "KarpenterNodeRole-task-management-eks"

      amiSelectorTerms = [
        {
          alias = "al2023@latest"
        }
      ]

      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = "task-management-eks"
          }
        }
      ]

      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = "task-management-eks"
          }
        }
      ]
    }
  }

  depends_on = [
    helm_release.karpenter,
    aws_iam_role.karpenter_node_role
  ]
}
