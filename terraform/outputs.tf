output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = module.eks.node_group_arn
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "eks_cluster_ca_cert" {
  description = "EKS cluster CA certificate (base64 encoded)"
  value       = module.eks.cluster_ca_cert
  sensitive   = true
}

output "efs_storage_bucket" {
  description = "S3 bucket for EFS storage"
  value       = "N/A - EFS module not configured"
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.security.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID"
  value       = module.security.eks_nodes_security_group_id
}

# Monitoring outputs
output "log_group_application" {
  description = "Application log group name"
  value       = module.monitoring.log_group_application
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = module.monitoring.sns_topic_arn
}

# RDS outputs
output "db_endpoint" {
  description = "Database endpoint address"
  value       = module.rds.db_endpoint
}

output "db_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.db_security_group_id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security.alb_security_group_id
}