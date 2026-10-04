variable "aws_region" {
  description = "Aws Region"
  type        = string
}
variable "eks_vpc_cidr" {
  description = "CIDR block for EKS VPC"
  type        = string
}
variable "eks_public_subnets" {
  description = "Public subnet CIDRs for EKS VPC"
  type        = list(string)

}
variable "eks_private_subnets" {
  description = "Private subnet CIDRs for EKS VPC"
  type        = list(string)
}
variable "access_vpc_cidr" {
  description = "CIDR block for Access VPC"
  type        = string
}
variable "access_public_subnets" {
  description = "Public subnet CIDRs for Access VPC"
  type        = list(string)
}
variable "access_private_subnets" {
  description = "Private subnet CIDRs for Access VPC"
  type        = list(string)
}
variable "environment" {
  description = "Environment Name"
  type        = string
}
variable "eks_cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes Version"
  type        = string
}

variable "node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
}

variable "node_min_size" {
  description = "Minimum EKS NODE"
  type        = number
}
variable "node_max_size" {
  description = "Maximum EKS NODE"
  type        = number

}
variable "node_desired_size" {
  description = "Desired Number of NODE"
  type        = number

}
