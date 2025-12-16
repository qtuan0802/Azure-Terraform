#!/usr/bin/env bash
# Final validation script for Microsoft Fabric Infrastructure

set -e

echo "🔍 Running Microsoft Fabric Infrastructure Validation..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if we're in the right directory
if [ ! -f "main.tf" ] || [ ! -d "modules" ]; then
    print_status "ERROR" "Please run this script from the fabric infrastructure directory"
    exit 1
fi

# Validate Terraform configuration
print_status "INFO" "Validating Terraform configuration..."

if command -v terraform &> /dev/null; then
    terraform init -backend=false > /dev/null 2>&1
    if terraform validate > /dev/null 2>&1; then
        print_status "SUCCESS" "Terraform configuration is valid"
    else
        print_status "ERROR" "Terraform validation failed"
        terraform validate
        exit 1
    fi
else
    print_status "ERROR" "Terraform is not installed"
    exit 1
fi

# Check formatting
print_status "INFO" "Checking Terraform formatting..."
if terraform fmt -check -recursive > /dev/null 2>&1; then
    print_status "SUCCESS" "Terraform files are properly formatted"
else
    print_status "WARNING" "Some Terraform files need formatting"
    terraform fmt -recursive
    print_status "INFO" "Files have been formatted"
fi

# Validate required files
print_status "INFO" "Checking required files..."

required_files=(
    "main.tf"
    "variables.tf"
    "outputs.tf"
    "backend.tf"
    "dev.tfvars"
    "staging.tfvars"
    "prod.tfvars"
    "dev.tfbackend"
    "staging.tfbackend"
    "prod.tfbackend"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    print_status "SUCCESS" "All required files are present"
else
    print_status "ERROR" "Missing required files: ${missing_files[*]}"
    exit 1
fi

# Validate module structure
print_status "INFO" "Validating module structure..."

required_modules=(
    "modules/workspace"
    "modules/data_factory"
    "modules/key_vault"
    "modules/storage"
    "modules/monitoring"
)

missing_modules=()
for module in "${required_modules[@]}"; do
    if [ ! -d "$module" ] || [ ! -f "$module/main.tf" ]; then
        missing_modules+=("$module")
    fi
done

if [ ${#missing_modules[@]} -eq 0 ]; then
    print_status "SUCCESS" "All required modules are present"
else
    print_status "ERROR" "Missing or incomplete modules: ${missing_modules[*]}"
    exit 1
fi

# Validate scripts
print_status "INFO" "Checking automation scripts..."

if [ -f "scripts/deploy.sh" ] && [ -x "scripts/deploy.sh" ]; then
    print_status "SUCCESS" "Deployment script (bash) is present and executable"
else
    print_status "WARNING" "Deployment script (bash) is missing or not executable"
fi

if [ -f "scripts/deploy.ps1" ]; then
    print_status "SUCCESS" "Deployment script (PowerShell) is present"
else
    print_status "WARNING" "Deployment script (PowerShell) is missing"
fi

# Validate CI/CD workflows
print_status "INFO" "Checking CI/CD workflows..."

if [ -f ".github/workflows/fabric-infrastructure.yml" ]; then
    print_status "SUCCESS" "Main CI/CD workflow is present"
else
    print_status "WARNING" "Main CI/CD workflow is missing"
fi

if [ -f ".github/workflows/destroy-infrastructure.yml" ]; then
    print_status "SUCCESS" "Destroy workflow is present"
else
    print_status "WARNING" "Destroy workflow is missing"
fi

# Validate documentation
print_status "INFO" "Checking documentation..."

if [ -f "README.md" ] && [ -s "README.md" ]; then
    print_status "SUCCESS" "README documentation is present"
else
    print_status "WARNING" "README documentation is missing or empty"
fi

if [ -f "DEPLOYMENT.md" ] && [ -s "DEPLOYMENT.md" ]; then
    print_status "SUCCESS" "Deployment documentation is present"
else
    print_status "WARNING" "Deployment documentation is missing or empty"
fi

# Check for secrets or sensitive data
print_status "INFO" "Scanning for potential secrets..."

secret_patterns=(
    "password\s*=\s*\"[^\"]+\""
    "secret\s*=\s*\"[^\"]+\""
    "key\s*=\s*\"[^\"]+\""
    "token\s*=\s*\"[^\"]+\""
    "client_secret\s*=\s*\"[^\"]+\""
)

found_secrets=false
for pattern in "${secret_patterns[@]}"; do
    if grep -r -E "$pattern" . --exclude-dir=.git --exclude="*.md" > /dev/null 2>&1; then
        print_status "WARNING" "Potential hardcoded secret found: $pattern"
        found_secrets=true
    fi
done

if [ "$found_secrets" = false ]; then
    print_status "SUCCESS" "No hardcoded secrets detected"
fi

# Summary
echo ""
echo "================================================"
print_status "INFO" "Validation Summary:"

total_checks=10
passed_checks=0

# Count successful validations (simplified for demo)
if terraform validate > /dev/null 2>&1; then ((passed_checks++)); fi
if terraform fmt -check -recursive > /dev/null 2>&1; then ((passed_checks++)); fi
if [ ${#missing_files[@]} -eq 0 ]; then ((passed_checks++)); fi
if [ ${#missing_modules[@]} -eq 0 ]; then ((passed_checks++)); fi
if [ -f "scripts/deploy.sh" ]; then ((passed_checks++)); fi
if [ -f "scripts/deploy.ps1" ]; then ((passed_checks++)); fi
if [ -f ".github/workflows/fabric-infrastructure.yml" ]; then ((passed_checks++)); fi
if [ -f ".github/workflows/destroy-infrastructure.yml" ]; then ((passed_checks++)); fi
if [ -f "README.md" ] && [ -s "README.md" ]; then ((passed_checks++)); fi
if [ "$found_secrets" = false ]; then ((passed_checks++)); fi

echo "Passed: $passed_checks/$total_checks checks"

if [ $passed_checks -eq $total_checks ]; then
    print_status "SUCCESS" "All validations passed! Infrastructure is ready for deployment."
    exit 0
elif [ $passed_checks -ge $((total_checks * 80 / 100)) ]; then
    print_status "WARNING" "Most validations passed. Review warnings before deployment."
    exit 0
else
    print_status "ERROR" "Multiple validation failures. Please fix issues before deployment."
    exit 1
fi