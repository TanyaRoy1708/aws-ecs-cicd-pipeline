output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  value = module.networking.database_subnet_ids
}

output "alb_sg_id" {
  value = module.security_groups.alb_sg_id
}

output "ecs_sg_id" {
  value = module.security_groups.ecs_sg_id
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL"
}

output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "ALB DNS name"
}

output "ecs_cluster_name" {
  value       = module.ecs.cluster_name
  description = "ECS cluster name"
}

output "rds_endpoint" {
  value       = module.rds.db_endpoint
  description = "RDS DB Endpoint"
}

output "redis_endpoint" {
  value       = module.elasticache.redis_endpoint
  description = "Redis endpoint"
}

output "jenkins_private_ip" {
  value       = module.jenkins.jenkins_private_ip
  description = "Jenkins private IP address"
}

