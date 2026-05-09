data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source              = "./module/vpc"
  name                = var.project_name
  cidr_block          = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_ecs_subnets = var.private_ecs_subnets
  private_db_subnets  = var.private_db_subnets
  availability_zones  = slice(data.aws_availability_zones.available.names, 0, 2)
  enable_nat_gateway  = true
  single_nat_gateway  = false
  tags                = local.common_tags
}

module "security_groups" {
  source         = "./module/security-groups"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr       = var.vpc_cidr
  name_prefix    = var.project_name
  container_port = var.container_port
  enable_https   = var.certificate_arn != "" ? true : false
  tags           = local.common_tags
}

module "iam" {
  source                       = "./module/iam"
  project_name                 = var.project_name
  ecs_task_execution_role_name = var.ecs_task_execution_role_name
  ecs_task_role_name           = var.ecs_task_role_name
  secrets_manager_secret_arns  = [module.rds.database_secret_arn]
  tags                         = local.common_tags
}

module "alb" {
  source                     = "./module/alb"
  name                       = var.project_name
  vpc_id                     = module.vpc.vpc_id
  public_subnets             = module.vpc.public_subnet_ids
  alb_security_group_id      = module.security_groups.alb_sg_id
  alb_logs_bucket            = var.alb_logs_bucket
  certificate_arn            = var.certificate_arn
  enable_https               = var.certificate_arn != "" ? true : false
  enable_deletion_protection = true
  enable_waf                 = var.enable_waf
  tags                       = local.common_tags
}

module "ecs" {
  source                  = "./module/ecs"
  cluster_name            = var.project_name
  service_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_ecs_subnet_ids
  ecs_security_group_id   = module.security_groups.ecs_sg_id
  target_group_arn        = module.alb.target_group_arn
  execution_role_arn      = module.iam.ecs_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn
  container_image         = var.container_image
  container_port          = var.container_port
  cpu                     = var.ecs_task_cpu
  memory                  = var.ecs_task_memory
  desired_count           = var.ecs_desired_count
  min_count               = var.ecs_min_count
  max_count               = var.ecs_max_count
  auto_scaling_cpu_target = var.ecs_cpu_target
  database_host           = module.rds.database_endpoint
  database_name           = var.database_name
  database_secret_arn     = module.rds.database_secret_arn
  aws_region              = var.aws_region
  awslogs_group           = "/ecs/${var.project_name}"
  log_retention_days      = var.log_retention_days
  enable_execute_command  = true
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  tags                    = local.common_tags
}

module "rds" {
  source                     = "./module/rds"
  identifier                 = var.project_name
  database_name              = var.database_name
  engine_version             = var.rds_engine_version
  instance_class             = var.rds_instance_class
  allocated_storage          = var.rds_allocated_storage
  multi_az                   = var.rds_multi_az
  vpc_id                     = module.vpc.vpc_id
  db_subnet_ids              = module.vpc.private_db_subnet_ids
  db_security_group_id       = module.security_groups.rds_sg_id
  lambda_security_group_id   = module.security_groups.rotation_lambda_sg_id
  subnet_ids_for_lambda      = module.vpc.private_ecs_subnet_ids
  master_username            = var.rds_master_username
  backup_retention_period    = var.rds_backup_retention
  deletion_protection        = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.project_name}-final-snapshot"
  auto_minor_version_upgrade = true
  storage_encrypted          = true
  rotation_enabled           = true
  rotation_interval_days     = 30
  tags                       = local.common_tags
}
