output "secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "The ARN of the secret"
}
