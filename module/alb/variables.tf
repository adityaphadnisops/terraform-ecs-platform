variable "name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnets" {
  type = list(string)
}
variable "alb_security_group_id" {
  type = string
}
variable "alb_logs_bucket" {
  type = string
}
variable "certificate_arn" {
  type    = string
  default = ""
}
variable "enable_https" {
  type    = bool
  default = false
}
variable "enable_deletion_protection" {
  type    = bool
  default = true
}
variable "container_port" {
  type    = number
  default = 80
}
variable "health_check_path" {
  type    = string
  default = "/"
}
variable "enable_waf" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
