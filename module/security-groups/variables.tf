variable "name_prefix" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "container_port" {
  type    = number
  default = 80
}
variable "enable_https" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
