# resource "helm_release" "karpenter" {

#   name = "karpenter"

#   namespace = var.karpenter_namespace

#   create_namespace = false

#   repository = "oci://public.ecr.aws/karpenter"

#   chart = "karpenter"

#   version = var.karpenter_version

#   wait = true

#   timeout = 900

#   values = [

#     yamlencode({

#       serviceAccount = {
#         name = "karpenter"
#       }

#       settings = {
#         clusterName = var.eks_cluster_name

#         clusterEndpoint = data.aws_eks_cluster.this.endpoint
#       }

#       controller = {
#         resources = {
#           requests = {
#             cpu    = "200m"
#             memory = "256Mi"
#           }

#           limits = {
#             cpu    = "1"
#             memory = "1Gi"
#           }
#         }
#       }

#     })
#   ]

#   depends_on = [
#     aws_eks_pod_identity_association.karpenter
#   ]
# }


resource "helm_release" "karpenter_t" {
  name             = "karpenter"
  namespace        = var.karpenter_namespace
  create_namespace = true

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  wait          = true
  wait_for_jobs = true
  timeout       = 900

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "karpenter"
      }

      settings = {
        clusterName     = var.eks_cluster_name
        clusterEndpoint = data.aws_eks_cluster.this.endpoint
      }

      controller = {
        resources = {
          requests = {
            cpu    = "200m"
            memory = "256Mi"
          }

          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }
    })
  ]

  depends_on = [
    aws_eks_pod_identity_association.karpenter
  ]
}
