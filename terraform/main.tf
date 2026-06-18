module "networking" {
  source     = "./modules/networking"
  project    = var.project
  aws_region = var.aws_region
  vpce_sg_id = module.security_groups.vpce_sg_id
}

module "security_groups" {
  source  = "./modules/security_groups"
  project = var.project
  vpc_id  = module.networking.vpc_id
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
}

module "ecr" {
  source  = "./modules/ecr"
  project = var.project
}

module "secrets" {
  source      = "./modules/secrets"
  project     = var.project
  db_password = var.db_password
}

module "rds" {
  source              = "./modules/rds"
  project             = var.project
  database_subnet_ids = module.networking.database_subnet_ids
  rds_sg_id           = module.security_groups.rds_sg_id
  db_password         = var.db_password
}

module "elasticache" {
  source              = "./modules/elasticache"
  project             = var.project
  database_subnet_ids = module.networking.database_subnet_ids
  redis_sg_id         = module.security_groups.redis_sg_id
}

module "alb" {
  source            = "./modules/alb"
  project           = var.project
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

module "ecs" {
  source                  = "./modules/ecs"
  project                 = var.project
  aws_region              = var.aws_region
  private_subnet_ids      = module.networking.private_subnet_ids
  ecs_sg_id               = module.security_groups.ecs_sg_id
  alb_target_group_arn    = module.alb.target_group_arn
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn
  ecr_repository_url      = module.ecr.repository_url
  db_endpoint             = module.rds.db_endpoint
  db_name                 = module.rds.db_name
  redis_endpoint          = module.elasticache.redis_endpoint
  secret_arn              = module.secrets.secret_arn
}

module "jenkins" {
  source                = "./modules/jenkins"
  project               = var.project
  vpc_id                = module.networking.vpc_id
  private_subnet_id     = module.networking.private_subnet_ids[0]
  jenkins_sg_id         = module.security_groups.jenkins_sg_id
  instance_profile_name = module.iam.jenkins_instance_profile_name
  key_name              = var.jenkins_key_name
}

