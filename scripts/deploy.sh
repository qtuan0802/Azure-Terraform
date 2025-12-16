#!/bin/bash

# Microsoft Fabric Infrastructure Deployment Script
# This script automates the deployment of Microsoft Fabric infrastructure
# across different environments using Terraform.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$ROOT_DIR"

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -e, --environment   Environment (dev|staging|prod) [required]"
    echo "  -a, --action        Action (init|plan|apply|destroy) [required]"
    echo "  -y, --auto-approve  Skip interactive approval for apply/destroy"
    echo "  -s, --skip-init     Skip Terraform initialization"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e dev -a plan"
    echo "  $0 -e prod -a apply -y"
    echo "  $0 -e staging -a destroy"
}

# Function to check prerequisites
check_prerequisites() {
    print_message "$BLUE" "[INFO] Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_message "$RED" "[ERROR] Terraform is not installed or not in PATH"
        exit 1
    fi
    
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    print_message "$GREEN" "[SUCCESS] Terraform version: $tf_version"
    
    # Check if Azure CLI is installed and logged in
    if ! command -v az &> /dev/null; then
        print_message "$RED" "[ERROR] Azure CLI is not installed"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_message "$RED" "[ERROR] Azure CLI is not logged in. Run 'az login'"
        exit 1
    fi
    
    local az_user=$(az account show --query user.name -o tsv)
    print_message "$GREEN" "[SUCCESS] Azure CLI logged in as: $az_user"
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        print_message "$YELLOW" "[WARNING] jq is not installed. Some features may not work properly"
    fi
    
    # Check if required files exist
    local backend_file="$ENVIRONMENT.tfbackend"
    local vars_file="$ENVIRONMENT.tfvars"
    
    if [[ ! -f "$TERRAFORM_DIR/$backend_file" ]]; then
        print_message "$RED" "[ERROR] Backend file not found: $TERRAFORM_DIR/$backend_file"
        exit 1
    fi
    
    if [[ ! -f "$TERRAFORM_DIR/$vars_file" ]]; then
        print_message "$RED" "[ERROR] Variables file not found: $TERRAFORM_DIR/$vars_file"
        exit 1
    fi
    
    print_message "$GREEN" "[SUCCESS] All prerequisites met"
}

# Function to initialize Terraform
init_terraform() {
    print_message "$BLUE" "[INFO] Initializing Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    local backend_file="$ENVIRONMENT.tfbackend"
    local init_cmd="terraform init -backend-config=$backend_file"
    
    print_message "$YELLOW" "[EXEC] $init_cmd"
    
    if ! eval "$init_cmd"; then
        print_message "$RED" "[ERROR] Terraform init failed"
        exit 1
    fi
    
    print_message "$GREEN" "[SUCCESS] Terraform initialized"
}

# Function to run Terraform plan
run_terraform_plan() {
    print_message "$BLUE" "[INFO] Running Terraform plan..."
    
    local vars_file="$ENVIRONMENT.tfvars"
    local plan_file="tfplan-$ENVIRONMENT"
    local plan_cmd="terraform plan -var-file=$vars_file -out=$plan_file"
    
    print_message "$YELLOW" "[EXEC] $plan_cmd"
    
    if ! eval "$plan_cmd"; then
        print_message "$RED" "[ERROR] Terraform plan failed"
        exit 1
    fi
    
    print_message "$GREEN" "[SUCCESS] Terraform plan completed. Plan saved to: $plan_file"
}

# Function to run Terraform apply
run_terraform_apply() {
    print_message "$BLUE" "[INFO] Running Terraform apply..."
    
    local vars_file="$ENVIRONMENT.tfvars"
    local plan_file="tfplan-$ENVIRONMENT"
    local apply_cmd
    
    if [[ -f "$plan_file" ]]; then
        if [[ "$AUTO_APPROVE" == "true" ]]; then
            apply_cmd="terraform apply -auto-approve $plan_file"
        else
            apply_cmd="terraform apply $plan_file"
        fi
    else
        if [[ "$AUTO_APPROVE" == "true" ]]; then
            apply_cmd="terraform apply -var-file=$vars_file -auto-approve"
        else
            apply_cmd="terraform apply -var-file=$vars_file"
        fi
    fi
    
    print_message "$YELLOW" "[EXEC] $apply_cmd"
    
    if ! eval "$apply_cmd"; then
        print_message "$RED" "[ERROR] Terraform apply failed"
        exit 1
    fi
    
    print_message "$GREEN" "[SUCCESS] Terraform apply completed"
}

# Function to run Terraform destroy
run_terraform_destroy() {
    print_message "$YELLOW" "[WARNING] This will destroy all resources in $ENVIRONMENT environment"
    
    if [[ "$AUTO_APPROVE" != "true" ]]; then
        echo -n "Are you sure you want to destroy? Type 'yes' to confirm: "
        read -r confirmation
        if [[ "$confirmation" != "yes" ]]; then
            print_message "$BLUE" "[INFO] Destroy cancelled"
            return
        fi
    fi
    
    local vars_file="$ENVIRONMENT.tfvars"
    local destroy_cmd
    
    if [[ "$AUTO_APPROVE" == "true" ]]; then
        destroy_cmd="terraform destroy -var-file=$vars_file -auto-approve"
    else
        destroy_cmd="terraform destroy -var-file=$vars_file"
    fi
    
    print_message "$YELLOW" "[EXEC] $destroy_cmd"
    
    if ! eval "$destroy_cmd"; then
        print_message "$RED" "[ERROR] Terraform destroy failed"
        exit 1
    fi
    
    print_message "$GREEN" "[SUCCESS] Terraform destroy completed"
}

# Parse command line arguments
ENVIRONMENT=""
ACTION=""
AUTO_APPROVE="false"
SKIP_INIT="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -y|--auto-approve)
            AUTO_APPROVE="true"
            shift
            ;;
        -s|--skip-init)
            SKIP_INIT="true"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            print_message "$RED" "[ERROR] Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ENVIRONMENT" ]]; then
    print_message "$RED" "[ERROR] Environment is required"
    print_usage
    exit 1
fi

if [[ -z "$ACTION" ]]; then
    print_message "$RED" "[ERROR] Action is required"
    print_usage
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_message "$RED" "[ERROR] Environment must be one of: dev, staging, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(init|plan|apply|destroy)$ ]]; then
    print_message "$RED" "[ERROR] Action must be one of: init, plan, apply, destroy"
    exit 1
fi

# Main execution
main() {
    print_message "$BLUE" "=== Microsoft Fabric Infrastructure Deployment ==="
    print_message "$BLUE" "Environment: $ENVIRONMENT"
    print_message "$BLUE" "Action: $ACTION"
    print_message "$BLUE" "Auto Approve: $AUTO_APPROVE"
    print_message "$BLUE" "==============================================="
    
    check_prerequisites
    
    if [[ "$SKIP_INIT" != "true" ]] || [[ "$ACTION" == "init" ]]; then
        init_terraform
    fi
    
    case "$ACTION" in
        "init")
            print_message "$GREEN" "[SUCCESS] Initialization completed"
            ;;
        "plan")
            run_terraform_plan
            ;;
        "apply")
            run_terraform_apply
            ;;
        "destroy")
            run_terraform_destroy
            ;;
    esac
    
    print_message "$GREEN" "[SUCCESS] Operation completed successfully"
}

# Execute main function
main "$@"