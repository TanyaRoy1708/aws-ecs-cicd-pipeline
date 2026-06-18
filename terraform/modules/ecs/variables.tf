variable "project" {
  type        = string
  description = "Project name"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ECS tasks"
}

variable "ecs_sg_id" {
  type        = string
  description = "ECS security group ID"
}

variable "alb_target_group_arn" {
  type        = string
  description = "ALB target group ARN"
}

variable "task_execution_role_arn" {
  type        = string
  description = "ECS Task Execution Role ARN"
}

variable "task_role_arn" {
  type        = string
  description = "ECS Task Role ARN"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL"
}

variable "db_endpoint" {
  type        = string
  description = "RDS DB Endpoint"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "redis_endpoint" {
  type        = string
  description = "Redis endpoint"
}

variable "secret_arn" {
  type        = string
  description = "AWS Secrets Manager ARN for DB password"
}

variable "container_port" {
  type        = number
  default     = 8000
  description = "Port exposed by the FastAPI application"
}

variable "cpu" {
  type        = number
  default     = 256
  description = "Fargate CPU units"
}

variable "memory" {
  type        = number
  default     = 512
  description = "Fargate memory in MB"
}
