variable "cluster_name" {
  type = string
}
variable "service_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "ecs_security_group_id" {
  type = string
}
variable "target_group_arn" {
  type = string
}
variable "execution_role_arn" {
  type = string
}
variable "task_role_arn" {
  type = string
}
variable "container_image" {
  type = string
}
variable "container_port" {
  type    = number
  default = 80
}
variable "cpu" {
  type    = number
  default = 1024
}
variable "memory" {
  type    = number
  default = 2048
}
variable "desired_count" {
  type    = number
  default = 2
}
variable "min_count" {
  type    = number
  default = 1
}
variable "max_count" {
  type    = number
  default = 4
}
variable "auto_scaling_cpu_target" {
  type    = number
  default = 60
}
variable "auto_scaling_memory_target" {
  type    = number
  default = 70
}
variable "database_host" {
  type = string
}
variable "database_name" {
  type = string
}
variable "database_secret_arn" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "awslogs_group" {
  type = string
}
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "enable_execute_command" {
  type    = bool
  default = true
}
variable "alb_arn_suffix" {
  type = string
}
variable "target_group_arn_suffix" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
