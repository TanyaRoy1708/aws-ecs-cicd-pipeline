variable "project" {
  type        = string
  description = "Project name"
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "List of database subnet IDs"
}

variable "rds_sg_id" {
  type        = string
  description = "RDS Security Group ID"
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}
