variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "task-management-eks"
}


variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "dev"
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "1.12.1"
}

variable "karpenter_namespace" {
  description = "Karpenter namespace"
  type        = string
  default     = "kube-system"
}

# IMPORTANT:
# Apne existing EKS private subnet IDs yahan daalna.
variable "karpenter_subnet_ids" {
  description = "Private subnet IDs where Karpenter can launch nodes"
  type        = list(string)

  default = [
    "subnet-029f6ce8fdd8e5175",
    "subnet-074315e68fa2fcef1"
  ]
}
