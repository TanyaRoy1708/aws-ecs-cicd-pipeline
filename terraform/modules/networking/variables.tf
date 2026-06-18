variable "project" {
  type        = string
  description = "Project name"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpce_sg_id" {
  type        = string
  description = "Security Group ID for VPC endpoints"
}
