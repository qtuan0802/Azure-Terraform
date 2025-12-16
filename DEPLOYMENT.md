# Microsoft Fabric Infrastructure Deployment Guide

This guide provides detailed instructions for deploying Microsoft Fabric infrastructure across different environments.

## 🎯 Deployment Overview

The deployment process follows a multi-stage approach:

1. **Development**: Continuous deployment for testing
2. **Staging**: Pre-production validation environment
3. **Production**: Live production environment with manual approval

## 📋 Pre-Deployment Checklist

### Azure Prerequisites

- [ ] Azure subscription with appropriate permissions
- [ ] Resource groups created for each environment
- [ ] Storage accounts created for Terraform state
- [ ] Service principals configured for CI/CD
- [ ] Microsoft Fabric capacity provisioned

### Configuration Prerequisites

- [ ] Environment-specific `.tfvars` files configured
- [ ] Backend configuration files updated
- [ ] RBAC groups and users identified
- [ ] Network security requirements defined
- [ ] Monitoring and alerting requirements documented

### Tools Prerequisites

- [ ] Azure CLI installed and configured
- [ ] Terraform >= 1.6.0 installed
- [ ] PowerShell Core or Bash available
- [ ] Git repository access configured

## 🚀 Deployment Methods

### Method 1: Automated CI/CD (Recommended)

#### Development Environment

1. **Trigger**: Push to `develop` branch
2. **Process**: Automatic validation → plan → apply
3. **Approval**: Not required

#### Staging Environment

1. **Trigger**: Push to `main` branch
2. **Process**: Validation → plan → manual approval → apply
3. **Approval**: Required via GitHub environment protection

#### Production Environment

1. **Trigger**: Manual workflow dispatch
2. **Process**: Validation → plan → manual approval → apply
3. **Approval**: Required via GitHub environment protection + additional stakeholder approval

#### Manual Workflow Trigger

1. Navigate to GitHub Actions in the repository
2. Select "Microsoft Fabric Infrastructure" workflow
3. Click "Run workflow"
4. Select environment and action:
   - Environment: `dev`, `staging`, or `prod`
   - Action: `plan`, `apply`, or `destroy`
5. Click "Run workflow"

### Method 2: Local Development

#### Using PowerShell Scripts (Windows)

```powershell
# Navigate to the fabric directory
cd infra-lovepop-common/fabric

# Initialize and plan
.\scripts\deploy.ps1 -Environment dev -Action init
.\scripts\deploy.ps1 -Environment dev -Action plan

# Review the plan output, then apply
.\scripts\deploy.ps1 -Environment dev -Action apply

# For production (with confirmation)
.\scripts\deploy.ps1 -Environment prod -Action apply
```

#### Using Bash Scripts (Linux/macOS)

```bash
# Navigate to the fabric directory
cd infra-lovepop-common/fabric

# Initialize and plan
./scripts/deploy.sh -e dev -a init
./scripts/deploy.sh -e dev -a plan

# Review the plan output, then apply
./scripts/deploy.sh -e dev -a apply

# For production (with auto-approve flag)
./scripts/deploy.sh -e prod -a apply -y
```

#### Using Raw Terraform Commands

```bash
# Initialize with backend configuration
terraform init -backend-config=dev.tfbackend

# Plan the deployment
terraform plan -var-file=dev.tfvars -out=tfplan

# Apply the plan
terraform apply tfplan
```

## 🔧 Environment-Specific Configurations

### Development Environment

**Configuration File**: `dev.tfvars`

```hcl
# Core Configuration
environment = "dev"
location = "East US"

# Fabric Configuration
fabric_capacity_id = "your-dev-capacity-id"
enable_data_factory = true

# RBAC Configuration
admin_users = [
  "devteam@lovepop.com"
]

contributor_users = [
  "developer1@lovepop.com",
  "developer2@lovepop.com"
]

# Storage Configuration
storage_account_tier = "Standard"
storage_replication_type = "LRS"
storage_network_rules = {
  default_action = "Allow"
  ip_rules = []
  virtual_network_subnet_ids = []
}

# Tags
tags = {
  Environment = "dev"
  Project = "Microsoft-Fabric"
  ManagedBy = "Terraform"
  CostCenter = "IT-Dev"
}
```

### Staging Environment

**Configuration File**: `staging.tfvars`

```hcl
# Core Configuration
environment = "staging"
location = "East US"

# Fabric Configuration
fabric_capacity_id = "your-staging-capacity-id"
enable_data_factory = true

# RBAC Configuration
admin_users = [
  "stagingadmin@lovepop.com"
]

# Storage Configuration
storage_account_tier = "Standard"
storage_replication_type = "GRS"
storage_network_rules = {
  default_action = "Deny"
  ip_rules = ["203.0.113.0/24"]
  virtual_network_subnet_ids = ["/subscriptions/.../subnets/staging-subnet"]
}

# Tags
tags = {
  Environment = "staging"
  Project = "Microsoft-Fabric"
  ManagedBy = "Terraform"
  CostCenter = "IT-Staging"
}
```

### Production Environment

**Configuration File**: `prod.tfvars`

```hcl
# Core Configuration
environment = "prod"
location = "East US"

# Fabric Configuration
fabric_capacity_id = "your-prod-capacity-id"
enable_data_factory = true

# RBAC Configuration
admin_users = [
  "fabricadmin@lovepop.com"
]

contributor_users = [
  "dataanalyst@lovepop.com"
]

viewer_users = [
  "businessuser@lovepop.com"
]

# Storage Configuration
storage_account_tier = "Premium"
storage_replication_type = "GRS"
storage_network_rules = {
  default_action = "Deny"
  ip_rules = []
  virtual_network_subnet_ids = ["/subscriptions/.../subnets/prod-subnet"]
}

# Key Vault Configuration
key_vault_access_policies = [
  {
    object_id = "prod-admin-group-id"
    key_permissions = ["Get", "List"]
    secret_permissions = ["Get", "List"]
    certificate_permissions = ["Get", "List"]
  }
]

# Tags
tags = {
  Environment = "prod"
  Project = "Microsoft-Fabric"
  ManagedBy = "Terraform"
  CostCenter = "IT-Production"
  Backup = "Required"
  Compliance = "SOX"
}
```

## 🔍 Validation and Testing

### Pre-Deployment Validation

```powershell
# Run validation script
.\scripts\validate.ps1 -Environment dev
```

### Post-Deployment Testing

1. **Infrastructure Validation**:
   ```bash
   # Check resource group
   az group show --name rg-fabric-dev-eus
   
   # Check storage account
   az storage account show --name stfabricdev1234 --resource-group rg-fabric-dev-eus
   
   # Check key vault
   az keyvault show --name kv-fabric-dev-1234
   ```

2. **Fabric Workspace Testing**:
   - Log into Power BI/Fabric portal
   - Verify workspace access and permissions
   - Test data source connections
   - Validate RBAC configurations

3. **Data Factory Testing**:
   - Access Azure Data Factory portal
   - Test linked services
   - Verify integration runtime connectivity

## 🚨 Rollback Procedures

### Automated Rollback

For development and staging environments, rollback can be automated:

```bash
# Using GitHub workflow
# 1. Navigate to GitHub Actions
# 2. Select "Destroy Microsoft Fabric Infrastructure"
# 3. Input environment and confirmation "DESTROY"
# 4. Run workflow
```

### Manual Rollback

```bash
# Using scripts
./scripts/deploy.sh -e dev -a destroy

# Using Terraform directly
terraform destroy -var-file=dev.tfvars
```

### Production Rollback

Production rollback requires additional approvals and should follow the change management process:

1. Create change request ticket
2. Get stakeholder approval
3. Schedule maintenance window
4. Execute rollback during approved window
5. Validate services after rollback
6. Update documentation and stakeholders

## 📊 Monitoring Deployment

### GitHub Actions Monitoring

1. **View Workflow Runs**:
   - Navigate to repository → Actions
   - Monitor workflow execution status
   - Review logs for any failures

2. **Notifications**:
   - Slack notifications for production deployments
   - Email notifications for failures
   - Teams integration for approvals

### Azure Resource Monitoring

1. **Resource Health**:
   ```bash
   az resource list --resource-group rg-fabric-dev-eus --output table
   ```

2. **Activity Logs**:
   - Monitor Azure Activity Log for deployment events
   - Set up alerts for critical failures
   - Review resource configuration changes

## 🔐 Security Considerations

### Deployment Security

- Service principals with minimal required permissions
- Secrets stored in GitHub secrets or Azure Key Vault
- Network access restrictions for production
- Audit logging for all deployment activities

### Runtime Security

- Private endpoints for production resources
- Network security groups for access control
- Identity-based access control (Azure AD)
- Regular security assessments and updates

## 📞 Escalation and Support

### Deployment Failures

1. **Level 1 - Self-Service**:
   - Check GitHub Actions logs
   - Review Terraform error messages
   - Validate configuration files
   - Consult this documentation

2. **Level 2 - Team Support**:
   - Contact DevOps team via Slack: #devops-fabric
   - Create GitHub issue with error details
   - Schedule team troubleshooting session

3. **Level 3 - Escalation**:
   - Contact DevOps team lead
   - Engage Azure support if needed
   - Escalate to management for critical failures

### Emergency Contacts

- **DevOps Team Lead**: devops-lead@lovepop.com
- **Infrastructure Manager**: infra-manager@lovepop.com
- **On-Call Engineer**: +1-555-DEVOPS-1

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Next Review**: March 2025