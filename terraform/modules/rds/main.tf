resource "aws_db_subnet_group" "rds" {
  name        = "${var.project}-rds-subnet-group"
  subnet_ids  = var.database_subnet_ids
  description = "Database subnet group for RDS PostgreSQL"

  tags = {
    Name = "${var.project}-rds-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.project}-postgres"
  allocated_storage      = 20
  max_allocated_storage  = 100
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t4g.micro"
  db_name                = "audit_log"
  username               = "postgres"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "${var.project}-postgres"
  }
}
