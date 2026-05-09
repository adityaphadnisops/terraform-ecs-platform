terraform {
  backend "s3" {
    # Only key specified; other values from backend.hcl
    key = "ecs-platform/terraform.tfstate"
  }
}
