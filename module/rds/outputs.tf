output "database_endpoint" { value = aws_db_proxy.this.endpoint }
output "database_secret_arn" { value = aws_secretsmanager_secret.database.arn }
output "database_id" { value = aws_db_instance.this.id }
