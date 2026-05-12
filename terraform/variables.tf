variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  default     = "blacklist"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "auth_bearer_token" {
  description = "Static bearer token for the API"
  type        = string
  sensitive   = true
}

variable "new_relic_license_key" {
  description = "New Relic license key for the Python agent"
  type        = string
  sensitive   = true
}
