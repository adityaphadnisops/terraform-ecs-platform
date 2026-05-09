output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "ALB DNS name"
}
output "rds_endpoint" {
  value       = module.rds.database_endpoint
  description = "RDS writer endpoint"
}
output "database_secret_arn" {
  value       = module.rds.database_secret_arn
  description = "ARN of database credentials secret"
}
