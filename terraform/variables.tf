variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "microservices-project"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dev-microservices-cluster"
}

variable "allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for security group"
  type        = list(string)
  default     = ["10.0.0.0/16"]  # Restricted by default
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}