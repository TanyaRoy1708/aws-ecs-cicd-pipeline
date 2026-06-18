resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project}-db-password"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}
