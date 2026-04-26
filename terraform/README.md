# Terraform Infrastructure for Microservices Project

## Directory Structure

```
terraform/
├── modules/                      # Reusable child modules
│   ├── vpc/                      # VPC networking module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/                 # Security groups module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/                      # EKS cluster module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/                      # RDS database module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/               # CloudWatch monitoring module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/                 # Environment-specific parent modules
    └── dev/                      # Development environment
        ├── providers.tf
        ├── variables.tf
        ├── main.tf              # Composes all child modules
        ├── outputs.tf
        └── terraform.tfvars     # Dev-specific values
```

## Architecture

### Parent-Child Module Pattern

- **Child Modules** (`terraform/modules/`): Reusable, self-contained modules that handle specific infrastructure components
  - Each module manages a specific resource type (VPC, Security, EKS, RDS, Monitoring)
  - Highly configurable via variables
  - Produce outputs for consumption by parent modules

- **Parent Modules** (`terraform/environments/dev/`): Environment-specific compositions
  - Compose multiple child modules together
  - Define environment-specific values
  - Orchestrate the complete infrastructure for an environment

## Modules

### 1. VPC Module (`modules/vpc/`)
Creates networking infrastructure:
- VPC with configurable CIDR
- Public and private subnets across multiple AZs
- Internet Gateway for public subnets
- NAT Gateways for private subnet internet access
- Route tables and associations

**Key Variables:**
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `az_count`: Number of availability zones (default: 2)

### 2. Security Module (`modules/security/`)
Creates security groups:
- EKS cluster security group
- EKS node security group
- ALB security group

### 3. EKS Module (`modules/eks/`)
Creates Kubernetes infrastructure:
- EKS cluster with logging enabled
- Node groups with auto-scaling
- IAM roles and policies
- EKS add-ons (coredns, kube-proxy, vpc-cni)
- OIDC provider for IRSA (IAM Roles for Service Accounts)

**Key Variables:**
- `node_instance_type`: EC2 instance type (default: t3.medium)
- `node_desired_capacity`: Desired number of nodes (default: 2)
- `kubernetes_version`: K8s version (default: 1.28)

### 4. RDS Module (`modules/rds/`)
Creates database infrastructure:
- RDS instance with encryption
- DB subnet group
- Security group for database access
- Optional Multi-AZ deployment

**Key Variables:**
- `enable_rds`: Enable/disable RDS (default: true)
- `db_instance_class`: Instance size (default: db.t3.micro)
- `db_engine`: Database engine (default: postgres)

### 5. Monitoring Module (`modules/monitoring/`)
Creates monitoring and alerting:
- CloudWatch log groups
- CloudWatch dashboard
- SNS topic for alerts
- CloudWatch metric alarms

## Environment Setup

### Development Environment (`environments/dev/`)

The development environment is the main parent module that composes all child modules with dev-specific values.

**Configuration Files:**
- `providers.tf`: Terraform and provider configuration with S3 backend
- `variables.tf`: Variable definitions
- `main.tf`: Module composition
- `outputs.tf`: Output definitions
- `terraform.tfvars`: Dev-specific values

## Usage

### Initialize Infrastructure

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Plan the infrastructure
terraform plan

# Apply the configuration
terraform apply
```

### Update Values

Edit `terraform/environments/dev/terraform.tfvars` to customize:
- Region
- Cluster name
- VPC CIDR
- Node instance types and capacity
- Database configuration
- Alert email

### View Outputs

```bash
terraform output

# Get specific output
terraform output cluster_endpoint
terraform output db_endpoint
```

### Configure kubectl

After deployment, configure kubectl to access the cluster:

```bash
aws eks update-kubeconfig \
  --name $(terraform output -raw cluster_name) \
  --region us-east-1
```

## Scaling

### Add Production Environment

To add a production environment, create:

```bash
mkdir -p terraform/environments/prod

# Copy dev environment structure
cp -r terraform/environments/dev/* terraform/environments/prod/

# Edit prod-specific values in terraform.tfvars
nano terraform/environments/prod/terraform.tfvars

# Deploy production
cd terraform/environments/prod
terraform apply
```

### Add New Modules

1. Create new module directory in `terraform/modules/`
2. Implement `main.tf`, `variables.tf`, `outputs.tf`
3. Import in environment parent module (`environments/*/main.tf`)

## Security Best Practices

- S3 backend for state management (encrypted, versioned)
- RDS encryption enabled
- Security groups with least-privilege access
- IAM roles with specific policies
- CloudWatch logging for audit trails
- Network isolation with public/private subnets

## Cost Optimization

- Use t3 instances for non-production (burstable)
- Configure auto-scaling
- Enable RDS backup retention (7 days default)
- Adjust CloudWatch retention (30 days default)