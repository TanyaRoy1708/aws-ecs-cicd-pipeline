output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "The name of the ECS cluster"
}

output "cluster_arn" {
  value       = aws_ecs_cluster.main.arn
  description = "The ARN of the ECS cluster"
}

output "service_name" {
  value       = aws_ecs_service.app.name
  description = "The name of the ECS service"
}
