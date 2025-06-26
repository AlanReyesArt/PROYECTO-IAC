variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "notification_email" {
  description = "Email for notifications"
  type        = string
  default     = "admin@example.com"
}