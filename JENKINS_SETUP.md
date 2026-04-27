# Jenkins Pipeline Setup Guide

This project uses **two separate pipelines** for managing infrastructure and microservices:

## 1. Infrastructure Pipeline (`Jenkinsfile.infrastructure`)
Manages AWS infrastructure provisioning using Terraform.

### When to use:
- Initial infrastructure setup
- Infrastructure changes (VPC, EKS, RDS, Security groups, Monitoring)
- Infrastructure destruction

### Parameters:
- **ACTION**: `plan` | `apply` | `destroy` - Terraform action to perform
- **ENVIRONMENT**: (default: `dev`) - Environment name for workspaces

### Example Flow:
```
1. Run with ACTION=plan → Review changes
2. Run with ACTION=apply → Deploy infrastructure
```

---

## 2. Deployment Pipeline (`Jenkinsfile`)
Builds, pushes, and deploys microservices to EKS.

### When to use:
- Building and deploying services
- Updating service versions
- Deploying specific or all microservices

### Parameters:
- **SERVICE**: `all` | `order-service` | `user-service` - Services to deploy
- **ENVIRONMENT**: (default: `dev`) - Environment to deploy to

### Example Flow:
```
1. Make code changes
2. Run pipeline with SERVICE=order-service
3. Pipeline builds, pushes to ECR, and deploys to EKS
```

---

## Jenkins Credentials Required

Create these credentials in Jenkins **Manage Credentials**:

| Credential ID | Type | Description |
|---|---|---|
| `aws-credentials` | AWS Credentials | AWS Access Key + Secret Key |
| `ecr-registry-url` | Secret text | ECR registry URL (e.g., `123456789.dkr.ecr.us-east-1.amazonaws.com`) |

### Setup Steps:

1. **Add AWS Credentials**:
   - Go to: Manage Jenkins → Manage Credentials → Store: Jenkins → Global
   - Click "Add Credentials"
   - Kind: `AWS Credentials`
   - ID: `aws-credentials`
   - Access Key ID: Your AWS access key
   - Secret Access Key: Your AWS secret key

2. **Add ECR Registry URL**:
   - Click "Add Credentials"
   - Kind: `Secret text`
   - Secret: Your ECR registry URL
   - ID: `ecr-registry-url`

---

## Workflow Example

### First Time Setup:
```
1. Pipeline: Jenkinsfile.infrastructure
   Parameters: ACTION=plan, ENVIRONMENT=dev
   → Review terraform plan

2. Pipeline: Jenkinsfile.infrastructure
   Parameters: ACTION=apply, ENVIRONMENT=dev
   → Creates EKS cluster, VPC, RDS, etc.

3. Pipeline: Jenkinsfile
   Parameters: SERVICE=all, ENVIRONMENT=dev
   → Builds, pushes, and deploys all services
```

### Ongoing Updates:
```
Update code → Run Deployment Pipeline (Jenkinsfile) → Services updated
```

### Infrastructure Changes:
```
Modify terraform → Run Infrastructure Pipeline (Jenkinsfile.infrastructure)
```

---

## Key Simplifications

✅ **Separated concerns** - Infrastructure and deployment are independent
✅ **No tool installation** - Assumes Jenkins has Docker, kubectl, Terraform installed
✅ **Cleaner credentials** - Uses `withAWS()` plugin instead of manual configuration
✅ **Reduced complexity** - Removed conflicting parameters and unnecessary stages
✅ **Better maintainability** - Each pipeline has one clear purpose
