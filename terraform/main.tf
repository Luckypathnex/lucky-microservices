module "vpc" {
  source = "./modules/vpc"

  region       = var.region
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
  tags         = local.common_tags
}

module "security" {
  source = "./modules/security"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks  # Configure in variables.tf for security
  tags               = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  project_name            = var.project_name
  environment             = var.environment
  cluster_name            = var.cluster_name
  kubernetes_version      = "1.31"
  public_subnet_ids       = module.vpc.public_subnet_ids
  private_subnet_ids      = module.vpc.private_subnet_ids
  cluster_security_group_id = module.security.eks_cluster_security_group_id
  node_instance_type      = var.node_instance_type
  node_desired_capacity   = var.node_desired_capacity
  node_min_capacity       = var.node_min_capacity
  node_max_capacity       = var.node_max_capacity
  tags                    = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  region               = var.region
  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = var.cluster_name
  alert_email          = ""
  log_retention_days   = 30
  tags                 = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  project_name                 = var.project_name
  environment                  = var.environment
  vpc_id                       = module.vpc.vpc_id
  private_subnet_ids           = module.vpc.private_subnet_ids
  eks_nodes_security_group_id  = module.security.eks_nodes_security_group_id
  tags                         = local.common_tags
}