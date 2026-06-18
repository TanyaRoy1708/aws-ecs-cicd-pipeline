# Security Group for Application Load Balancer (Public Ingress)
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Allow inbound HTTP/HTTPS traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP from public"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from public"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Outbound to ECS tasks"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Will be restricted to private subnets / ECS security group later
  }

  tags = {
    Name = "${var.project}-alb-sg"
  }
}

# Security Group for ECS Tasks (Private Workloads)
resource "aws_security_group" "ecs" {
  name        = "${var.project}-ecs-sg"
  description = "Security Group for ECS Fargate Tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on port 8000"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description      = "Outbound to Internet and VPC endpoints"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-ecs-sg"
  }
}

# Security Group for VPC Endpoints (PrivateLink endpoints)
resource "aws_security_group" "vpce" {
  name        = "${var.project}-vpce-sg"
  description = "Security Group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS ingress from ECS tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description      = "Allow outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-vpce-sg"
  }
}

# Security Group for Jenkins EC2 (Private CI/CD Server)
resource "aws_security_group" "jenkins" {
  name        = "${var.project}-jenkins-sg"
  description = "Security Group for Jenkins EC2 Instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow port 8080 from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-jenkins-sg"
  }
}

# Security Group for RDS PostgreSQL (Private Database)
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Security Group for RDS PostgreSQL Database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL access from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  ingress {
    description     = "Allow PostgreSQL access from Jenkins"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-rds-sg"
  }
}

# Security Group for ElastiCache Redis (Private Cache)
resource "aws_security_group" "redis" {
  name        = "${var.project}-redis-sg"
  description = "Security Group for ElastiCache Redis Cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow Redis access from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  ingress {
    description     = "Allow Redis access from Jenkins"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-redis-sg"
  }
}

