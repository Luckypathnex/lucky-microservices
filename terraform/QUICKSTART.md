# Quick Start Guide

## Prerequisites

1. AWS Account with appropriate permissions
2. Terraform >= 1.0
3. AWS CLI configured
4. kubectl installed

## Step 1: Prepare S3 Backend (One-time Setup)

Before running Terraform, create the S3 bucket for state:

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for locks (optional)
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## Step 2: Update Backend Configuration

Edit `terraform/environments/dev/providers.tf`:

```hcl
backend "s3" {
  bucket         = "your-actual-bucket-name"  # Update this
  key            = "dev/microservices-project/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

## Step 3: Update Variables

Edit `terraform/environments/dev/terraform.tfvars`:

```hcl
alert_email = "your-email@example.com"  # Update for alerts
```

## Step 4: Deploy Infrastructure

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Review what will be created
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# View outputs
terraform output
```

## Step 5: Configure kubectl

```bash
# Get cluster credentials
aws eks update-kubeconfig \
  --name $(terraform output -raw cluster_name) \
  --region us-east-1

# Verify connection
kubectl get nodes
```

## Common Commands

### View cluster info
```bash
terraform output cluster_endpoint
terraform output cluster_name
```

### Get database credentials
```bash
terraform output db_endpoint
terraform output -json db_username
terraform output -json db_password  # Sensitive output
```

### View logs and metrics
```bash
terraform output dashboard_url
terraform output log_group_application
```

### Update configuration
```bash
# Edit tfvars and reapply
nano terraform.tfvars
terraform apply
```

### Destroy infrastructure (use with caution!)
```bash
terraform destroy
```

## Troubleshooting

### State lock issues
If stuck in locked state, manually unlock:
```bash
terraform force-unlock <LOCK_ID>
```

### Backend access denied
Verify AWS credentials and S3 bucket permissions:
```bash
aws s3 ls s3://your-terraform-state-bucket/
```

### EKS cluster not accessible
Ensure kubeconfig is properly configured:
```bash
aws eks update-kubeconfig --name dev-microservices-cluster --region us-east-1
kubectl cluster-info
```

## Architecture Overview

The infrastructure creates:

1. **VPC** (10.0.0.0/16)
   - 2 Public subnets
   - 2 Private subnets
   - Internet Gateway
   - NAT Gateways

2. **EKS Cluster**
   - Kubernetes 1.28
   - 2 t3.medium nodes (min: 1, max: 5)
   - Auto-scaling enabled

3. **RDS Database**
   - PostgreSQL 15.3
   - t3.micro instance
   - 20GB storage with encryption
   - Multi-AZ capable (dev: disabled)

4. **Monitoring**
   - CloudWatch logs
   - CloudWatch dashboard
   - SNS alerts
   - CloudWatch alarms

5. **Security**
   - Separate security groups
   - Encrypted secrets
   - IAM roles and policies
   - KMS encryption keys

## Cost Estimation (Dev)

- EKS: ~$0.10/hour
- EC2 (2x t3.medium): ~$0.07/hour each
- RDS (t3.micro): ~$0.016/hour
- NAT Gateway: ~$32/month
- Data transfer: Variable

**Approximate monthly cost: $50-100**

Use `terraform plan` and AWS Pricing Calculator for accurate estimates.