# Microsoft Fabric Infrastructure

This repository contains Terraform configurations and automation scripts for deploying and managing Microsoft Fabric infrastructure across multiple environments.

## 🏗️ Architecture Overview

The infrastructure includes:

- **Microsoft Fabric Workspace**: Main workspace for data analytics and reporting
- **Azure Data Factory**: For data ingestion and ETL processes
- **Azure Key Vault**: Secure storage for secrets and certificates
- **Azure Storage Account**: OneLake integration and data storage
- **RBAC Configuration**: Role-based access control for different user groups

## 📁 Project Structure

```
fabric/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── backend.tf                 # Backend configuration
├── *.tfvars                   # Environment-specific variables
├── *.tfbackend               # Environment-specific backend configs
├── modules/                   # Terraform modules
│   ├── workspace/            # Fabric workspace module
│   ├── data_factory/         # Azure Data Factory module
│   ├── key_vault/           # Key Vault module
│   └── storage/             # Storage Account module
├── scripts/                  # Automation scripts
│   ├── deploy.ps1           # PowerShell deployment script
│   ├── deploy.sh            # Bash deployment script
│   └── validate.ps1         # Validation script
└── .github/workflows/       # GitHub Actions workflows
```

## 🚀 Getting Started

### Prerequisites

1. **Azure CLI**: Installed and logged in
   ```bash
   az login
   ```

2. **Terraform**: Version 1.6.0 or later
   ```bash
   terraform version
   ```

3. **PowerShell Core** (for Windows users) or **Bash** (for Linux/macOS users)

4. **Required Permissions**:
   - Contributor access to Azure subscription
   - Fabric Admin permissions
   - Key Vault access for secrets management

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd infra-lovepop-common/fabric
   ```

2. **Configure Azure Backend Storage**:
   
   Create storage account for Terraform state:
   ```bash
   # Create resource group
   az group create --name rg-terraform-state-dev --location "East US"
   
   # Create storage account
   az storage account create \
     --name stfabricstatedev \
     --resource-group rg-terraform-state-dev \
     --location "East US" \
     --sku Standard_LRS
   
   # Create container
   az storage container create \
     --name tfstate \
     --account-name stfabricstatedev
   ```

3. **Update Configuration Files**:
   
   Edit the environment-specific `.tfvars` files with your configuration:
   - `dev.tfvars`
   - `staging.tfvars`
   - `prod.tfvars`

   Update the `.tfbackend` files with your storage account details.

## 🔧 Deployment

### Using Automation Scripts

#### PowerShell (Windows)

```powershell
# Plan deployment
.\scripts\deploy.ps1 -Environment dev -Action plan

# Apply deployment
.\scripts\deploy.ps1 -Environment dev -Action apply

# Auto-approve deployment
.\scripts\deploy.ps1 -Environment prod -Action apply -AutoApprove
```

#### Bash (Linux/macOS)

```bash
# Plan deployment
./scripts/deploy.sh -e dev -a plan

# Apply deployment
./scripts/deploy.sh -e dev -a apply

# Auto-approve deployment
./scripts/deploy.sh -e prod -a apply -y
```

### Using Terraform Directly

```bash
# Initialize Terraform
terraform init -backend-config=dev.tfbackend

# Plan deployment
terraform plan -var-file=dev.tfvars

# Apply deployment
terraform apply -var-file=dev.tfvars
```

## 🎯 Environment Configuration

### Development Environment

- **Purpose**: Development and testing
- **Features**: 
  - Standard storage tier
  - LRS replication
  - Public network access allowed
  - Basic monitoring

### Staging Environment

- **Purpose**: Pre-production testing
- **Features**:
  - Standard storage tier
  - GRS replication
  - Restricted network access
  - Enhanced monitoring

### Production Environment

- **Purpose**: Live production workloads
- **Features**:
  - Premium storage tier
  - GRS replication
  - Private network access only
  - Full monitoring and alerting
  - Backup and disaster recovery

## 🔐 Security Configuration

### RBAC Roles

- **Admin**: Full control over Fabric workspace and resources
- **Contributor**: Can create and modify content
- **Viewer**: Read-only access to content

### Key Vault Integration

Secrets are stored in Azure Key Vault:
- Connection strings
- API keys
- Service principal credentials
- Custom application secrets

### Network Security

- Private endpoints for production environments
- Network security groups for access control
- Azure Firewall rules for outbound traffic

## 📊 Monitoring and Alerting

Monitoring is configured through Azure Monitor:

- **Metrics**: Resource utilization, performance counters
- **Logs**: Application logs, audit logs
- **Alerts**: Critical threshold breaches, failures
- **Dashboards**: Real-time monitoring views

## 🚨 Troubleshooting

### Common Issues

1. **Terraform Init Fails**
   ```bash
   # Check Azure CLI login
   az account show
   
   # Verify backend configuration
   cat dev.tfbackend
   ```

2. **Permission Denied Errors**
   ```bash
   # Check Azure permissions
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

3. **Resource Already Exists**
   ```bash
   # Import existing resource
   terraform import azurerm_resource_group.fabric /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}
   ```

### Validation

Run the validation script before deployment:

```powershell
.\scripts\validate.ps1 -Environment dev
```

## 🔄 CI/CD Pipeline

### GitHub Actions

The repository includes GitHub Actions workflows for:

- **Continuous Integration**: Validation and testing on PR
- **Continuous Deployment**: Automated deployment to environments
- **Infrastructure Destruction**: Controlled resource cleanup

### Workflow Triggers

- **Push to develop**: Deploy to development environment
- **Push to main**: Deploy to staging environment
- **Manual trigger**: Deploy to any environment including production

### Required Secrets

Configure these secrets in GitHub repository settings:

- `AZURE_CREDENTIALS_DEV`: Azure service principal for dev
- `AZURE_CREDENTIALS_STAGING`: Azure service principal for staging
- `AZURE_CREDENTIALS_PROD`: Azure service principal for prod
- `SLACK_WEBHOOK_URL`: Slack notifications webhook

## 📝 Configuration Reference

### Required Variables

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `environment` | Environment name | string | "dev" |
| `location` | Azure region | string | "East US" |
| `fabric_capacity_id` | Fabric capacity ID | string | "ABCD1234-..." |
| `admin_users` | Admin user emails | list(string) | ["admin@domain.com"] |

### Optional Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `enable_data_factory` | Enable Data Factory | true | bool |
| `storage_account_tier` | Storage tier | "Standard" | string |
| `enable_monitoring` | Enable monitoring | true | bool |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation scripts
5. Submit a pull request

### Development Guidelines

- Follow Terraform best practices
- Include comprehensive variable descriptions
- Add appropriate tags to all resources
- Write meaningful commit messages
- Update documentation for new features

## 📞 Support

For support and questions:

- Create an issue in this repository
- Contact the DevOps team via Slack: #devops-fabric
- Email: devops@lovepop.com

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Last Updated**: December 2024  
**Maintained By**: DevOps Team  
**Version**: 1.0.0