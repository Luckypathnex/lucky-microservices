variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Cluster security group ID"
  type        = string
}

variable "node_instance_type" {
  description = "Instance type for nodes"
  type        = string
}

variable "node_desired_capacity" {
  description = "Desired number of nodes"
  type        = number
}

variable "node_min_capacity" {
  description = "Minimum number of nodes"
  type        = number
}

variable "node_max_capacity" {
  description = "Maximum number of nodes"
  type        = number
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}