variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Project name tag value used to namespace resources"
  default     = "devops-toolbox"
}

variable "db_password" {
  type        = string
  description = "Database master password for RDS PostgreSQL"
  sensitive   = true
}

variable "jenkins_key_name" {
  type        = string
  description = "Optional key pair name to associate with Jenkins instance"
  default     = null
}

