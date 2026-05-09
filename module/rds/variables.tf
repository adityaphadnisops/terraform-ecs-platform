variable "identifier" {
  type = string
}
variable "database_name" {
  type = string
}
variable "engine_version" {
  type = string
}
variable "instance_class" {
  type = string
}
variable "allocated_storage" {
  type = number
}
variable "multi_az" {
  type = bool
}
variable "vpc_id" {
  type = string
}
variable "db_subnet_ids" {
  type = list(string)
}
variable "db_security_group_id" {
  type = string
}
variable "lambda_security_group_id" {
  type = string
}
variable "subnet_ids_for_lambda" {
  type = list(string)
}
variable "master_username" {
  type = string
}
variable "backup_retention_period" {
  type = number
}
variable "deletion_protection" {
  type = bool
}
variable "skip_final_snapshot" {
  type = bool
}
variable "final_snapshot_identifier" {
  type = string
}
variable "auto_minor_version_upgrade" {
  type = bool
}
variable "storage_encrypted" {
  type = bool
}
variable "rotation_enabled" {
  type = bool
}
variable "rotation_interval_days" {
  type    = number
  default = 30
}
variable "tags" {
  type = map(string)
}
