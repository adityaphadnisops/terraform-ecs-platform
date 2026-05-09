variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "project_name" {
  type    = string
  default = "ecs-platform"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "private_ecs_subnets" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}
variable "private_db_subnets" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}
variable "container_image" {
  type    = string
  default = "public.ecr.aws/nginx/nginx:latest"
}
variable "container_port" {
  type    = number
  default = 80
}
variable "ecs_task_cpu" {
  type    = number
  default = 1024
}
variable "ecs_task_memory" {
  type    = number
  default = 2048
}
variable "ecs_desired_count" {
  type    = number
  default = 2
}
variable "ecs_min_count" {
  type    = number
  default = 1
}
variable "ecs_max_count" {
  type    = number
  default = 4
}
variable "ecs_cpu_target" {
  type    = number
  default = 60
}
variable "ecs_task_execution_role_name" {
  type    = string
  default = "ecs-execution-role"
}
variable "ecs_task_role_name" {
  type    = string
  default = "ecs-task-role"
}
variable "certificate_arn" {
  type    = string
  default = ""
}
variable "alb_logs_bucket" {
  type    = string
  default = "my-alb-logs-unique-bucket"
}
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "database_name" {
  type    = string
  default = "appdb"
}
variable "rds_engine_version" {
  type    = string
  default = "16.4"
}
variable "rds_instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "rds_allocated_storage" {
  type    = number
  default = 20
}
variable "rds_multi_az" {
  type    = bool
  default = true
}
variable "rds_master_username" {
  type    = string
  default = "dbadmin"
}
variable "rds_backup_retention" {
  type    = number
  default = 7
}
variable "backend_s3_bucket" {
  type    = string
  default = "my-terraform-state-bucket-unique"
}
variable "backend_dynamodb_table" {
  type    = string
  default = "terraform-locks"
}
variable "backend_key" {
  type    = string
  default = "ecs-platform/terraform.tfstate"
}
variable "terraform_role_arn" {
  type    = string
  default = ""
}
variable "enable_waf" {
  type    = bool
  default = true
}
