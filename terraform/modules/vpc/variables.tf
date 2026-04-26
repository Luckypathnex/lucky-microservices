variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}