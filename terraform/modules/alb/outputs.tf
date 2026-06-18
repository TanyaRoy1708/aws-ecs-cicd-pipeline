output "alb_arn" {
  value       = aws_lb.main.arn
  description = "The ARN of the ALB"
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The DNS name of the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "The ARN of the target group"
}
