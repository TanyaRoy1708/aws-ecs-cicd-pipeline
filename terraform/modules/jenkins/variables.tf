variable "project" {
  type        = string
  description = "Project name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_id" {
  type        = string
  description = "Private subnet ID for Jenkins placement"
}

variable "jenkins_sg_id" {
  type        = string
  description = "Jenkins security group ID"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name for Jenkins"
}

variable "key_name" {
  type        = string
  default     = null
  description = "Optional SSH key pair name"
}
