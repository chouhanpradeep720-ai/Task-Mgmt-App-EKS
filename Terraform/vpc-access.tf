module "access_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "task-management-access-vpc"

  cidr = var.access_vpc_cidr

  azs = local.azs

  public_subnets = var.access_public_subnets

  private_subnets = var.access_private_subnets

  enable_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "task-managemebt-access-vpc"
  }

}
