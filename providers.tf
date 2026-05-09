provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn     = var.terraform_role_arn != "" ? var.terraform_role_arn : null
    session_name = "terraform"
  }
  default_tags {
    tags = local.common_tags
  }
}
