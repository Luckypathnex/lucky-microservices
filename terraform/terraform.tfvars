# AWS Region
region = "us-east-1"

# Environment
environment = "dev"

# Project name
project_name = "microservices-project"

# EKS Cluster
cluster_name = "dev-microservices-cluster"

# Network
vpc_cidr           = "10.0.0.0/16"
allowed_cidr_blocks = ["10.0.0.0/16"]

# Availability Zones
az_count = 2

# EKS Node Group
node_instance_type    = "t3.medium"
node_desired_capacity = 2
node_min_capacity     = 1
node_max_capacity     = 5