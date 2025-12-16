# Microsoft Fabric Infrastructure - Quick Start Guide

## 🚀 Quick Deployment

### Prerequisites Checklist
- [ ] Azure CLI installed and logged in (`az login`)
- [ ] Terraform >= 1.6.0 installed
- [ ] Microsoft Fabric capacity provisioned
- [ ] Required Azure permissions (Contributor + Fabric Admin)

### 1. Configure Environment

```bash
# Clone and navigate to the fabric infrastructure
cd infra-lovepop-common/fabric

# Copy and edit environment configuration
cp dev.tfvars.example dev.tfvars
```

Edit `dev.tfvars` with your specific values:
```hcl
# Required: Your Fabric capacity ID
fabric_capacity_id = "YOUR_FABRIC_CAPACITY_ID"

# Required: Admin users (use your email)
admin_users = ["your-email@domain.com"]

# Optional: Additional configuration
email_receivers = [
  {
    name          = "admin"
    email_address = "your-email@domain.com"
  }
]
```

### 2. Create Backend Storage

```bash
# Create storage for Terraform state
az group create --name rg-terraform-state-dev --location "East US"
az storage account create \
  --name stfabricstatedev \
  --resource-group rg-terraform-state-dev \
  --location "East US" \
  --sku Standard_LRS
az storage container create \
  --name tfstate \
  --account-name stfabricstatedev
```

Update `dev.tfbackend` with your storage account name.

### 3. Deploy Infrastructure

#### Option A: Using Scripts (Recommended)
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run validation
./scripts/final-validation.sh

# Deploy to development
./scripts/deploy.sh -e dev -a init
./scripts/deploy.sh -e dev -a plan
./scripts/deploy.sh -e dev -a apply
```

#### Option B: Using Terraform Directly
```bash
terraform init -backend-config=dev.tfbackend
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### 4. Verify Deployment

```bash
# Check created resources
az resource list --resource-group rg-fabric-dev-eus --output table

# Access Fabric workspace
# Navigate to https://app.powerbi.com and find your workspace
```

### 5. Next Steps

1. **Configure RBAC**: Add users and groups to appropriate roles
2. **Setup Data Sources**: Configure connections in Data Factory
3. **Configure Monitoring**: Review alerts and dashboards
4. **Deploy to Higher Environments**: Use staging.tfvars and prod.tfvars

## 📋 Common Issues & Solutions

### Issue: "Fabric capacity not found"
**Solution**: Ensure the `fabric_capacity_id` in your `.tfvars` file is correct and accessible.

### Issue: "Storage account name already exists"
**Solution**: Storage account names must be globally unique. The infrastructure uses a random suffix, but you may need to run `terraform apply` again.

### Issue: "Permission denied"
**Solution**: Verify you have Contributor access to the subscription and Fabric Admin permissions.

## 📞 Support

- GitHub Issues: [Create an issue](../../issues)
- Documentation: See [README.md](README.md) and [DEPLOYMENT.md](DEPLOYMENT.md)
- Team Slack: #devops-fabric

---

⏱️ **Estimated deployment time**: 10-15 minutes  
📊 **Resources created**: ~15 Azure resources + 1 Fabric workspace