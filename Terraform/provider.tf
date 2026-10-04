provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Task-Management-App"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
