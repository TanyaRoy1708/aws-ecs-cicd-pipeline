variable "project" {
  type        = string
  description = "Project name"
}

variable "db_password" {
  type        = string
  description = "Database master password to store"
  sensitive   = true
}
