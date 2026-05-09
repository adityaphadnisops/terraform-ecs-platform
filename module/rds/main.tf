resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-db-subnet"
  subnet_ids = var.db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.identifier}-db-subnet" })
}
resource "random_password" "master" {
  length  = 32
  special = false
}
resource "aws_secretsmanager_secret" "database" {
  name                    = "${var.identifier}-db-credentials"
  recovery_window_in_days = 7
  tags                    = var.tags
}
resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = 5432
    dbname   = var.database_name
  })
}
resource "aws_db_instance" "this" {
  identifier                      = var.identifier
  engine                          = "postgres"
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  allocated_storage               = var.allocated_storage
  storage_type                    = "gp3"
  storage_encrypted               = var.storage_encrypted
  multi_az                        = var.multi_az
  db_name                         = var.database_name
  username                        = var.master_username
  password                        = random_password.master.result
  port                            = 5432
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [var.db_security_group_id]
  publicly_accessible             = false
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  deletion_protection             = var.deletion_protection
  backup_retention_period         = var.backup_retention_period
  backup_window                   = "03:00-04:00"
  maintenance_window              = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = true
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_enhanced_monitoring.arn
  tags                            = merge(var.tags, { Name = var.identifier })
}
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.identifier}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]
  tags                = var.tags
}

# RDS Proxy
resource "aws_db_proxy" "this" {
  name                   = "${var.identifier}-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [var.db_security_group_id]
  vpc_subnet_ids         = var.db_subnet_ids
  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.database.arn
  }
  tags = var.tags
}
resource "aws_iam_role" "rds_proxy" {
  name = "${var.identifier}-rds-proxy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "rds_proxy_secrets" {
  role       = aws_iam_role.rds_proxy.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Rotation Lambda (Python)
data "archive_file" "rotation_lambda" {
  type        = "zip"
  source_file = "${path.module}/rotation_lambda/lambda_function.py"
  output_path = "${path.module}/rotation_lambda.zip"
}
resource "aws_lambda_function" "rotation" {
  filename         = data.archive_file.rotation_lambda.output_path
  function_name    = "${var.identifier}-secret-rotation"
  role             = aws_iam_role.rotation_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  source_code_hash = data.archive_file.rotation_lambda.output_base64sha256
  vpc_config {
    subnet_ids         = var.subnet_ids_for_lambda
    security_group_ids = [var.lambda_security_group_id]
  }
  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.database.arn
    }
  }
  tags = var.tags
}
resource "aws_iam_role" "rotation_lambda" {
  name = "${var.identifier}-rotation-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}
data "aws_iam_policy_document" "rotation_lambda" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage"
    ]
    resources = [aws_secretsmanager_secret.database.arn]
  }
  statement {
    actions = [
      "rds:ModifyDBInstance",
      "rds:DescribeDBInstances"
    ]
    resources = [aws_db_instance.this.arn]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "rotation_lambda" {
  name   = "${var.identifier}-rotation-lambda-policy"
  policy = data.aws_iam_policy_document.rotation_lambda.json
}
resource "aws_iam_role_policy_attachment" "rotation_lambda" {
  role       = aws_iam_role.rotation_lambda.name
  policy_arn = aws_iam_policy.rotation_lambda.arn
}
resource "aws_iam_role_policy_attachment" "rotation_lambda_basic" {
  role       = aws_iam_role.rotation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_secretsmanager_secret_rotation" "database" {
  count               = var.rotation_enabled ? 1 : 0
  secret_id           = aws_secretsmanager_secret.database.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn
  rotation_rules {
    automatically_after_days = var.rotation_interval_days
  }
}
resource "aws_lambda_permission" "secrets_manager" {
  count         = var.rotation_enabled ? 1 : 0
  statement_id  = "AllowSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.database.arn
}
