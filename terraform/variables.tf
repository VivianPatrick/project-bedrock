variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "student_id" {
  description = "Your AltSchool student ID suffix"
  type        = string
  default     = "4699"
}

variable "project_tag" {
  description = "Tag applied to all resources"
  default     = "karatu-2025-capstone"
}

variable "db_password" {
  description = "Password for RDS instances"
  type        = string
  sensitive   = true
}
