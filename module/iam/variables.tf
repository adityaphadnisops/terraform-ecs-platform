variable "project_name" {
  type = string
}
variable "ecs_task_execution_role_name" {
  type = string
}
variable "ecs_task_role_name" {
  type = string
}
variable "secrets_manager_secret_arns" {
  type = list(string)
}
variable "tags" {
  type    = map(string)
  default = {}
}
