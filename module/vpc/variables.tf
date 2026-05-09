variable "name" {
  type = string
}
variable "cidr_block" {
  type = string
}
variable "public_subnets" {
  type = list(string)
}
variable "private_ecs_subnets" {
  type = list(string)
}
variable "private_db_subnets" {
  type = list(string)
}
variable "availability_zones" {
  type = list(string)
}
variable "enable_nat_gateway" {
  type    = bool
  default = true
}
variable "single_nat_gateway" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
