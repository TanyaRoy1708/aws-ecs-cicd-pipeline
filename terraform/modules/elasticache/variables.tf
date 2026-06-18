variable "project" {
  type        = string
  description = "Project name"
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "List of database subnet IDs"
}

variable "redis_sg_id" {
  type        = string
  description = "Redis Security Group ID"
}
