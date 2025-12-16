#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy Microsoft Fabric Infrastructure using Terraform

.DESCRIPTION
    This script automates the deployment of Microsoft Fabric infrastructure
    across different environments (dev, staging, prod) using Terraform.

.PARAMETER Environment
    Target environment (dev, staging, prod)

.PARAMETER Action
    Action to perform (plan, apply, destroy)

.PARAMETER AutoApprove
    Skip interactive approval for apply/destroy

.EXAMPLE
    .\deploy.ps1 -Environment dev -Action plan
    .\deploy.ps1 -Environment prod -Action apply -AutoApprove
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('plan', 'apply', 'destroy', 'init')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipInit
)

# Configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootPath = Split-Path -Parent $scriptPath
$terraformDir = $rootPath
$backendFile = "$Environment.tfbackend"
$varsFile = "$Environment.tfvars"

# Colors for output
$colors = @{
    'Green' = 'Green'
    'Red' = 'Red'
    'Yellow' = 'Yellow'
    'Blue' = 'Blue'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Test-Prerequisites {
    Write-ColorOutput "[INFO] Checking prerequisites..." "Blue"
    
    # Check if Terraform is installed
    try {
        $tfVersion = terraform version -json | ConvertFrom-Json
        Write-ColorOutput "[SUCCESS] Terraform version: $($tfVersion.terraform_version)" "Green"
    }
    catch {
        Write-ColorOutput "[ERROR] Terraform is not installed or not in PATH" "Red"
        exit 1
    }
    
    # Check if Azure CLI is installed and logged in
    try {
        $azAccount = az account show --output json | ConvertFrom-Json
        Write-ColorOutput "[SUCCESS] Azure CLI logged in as: $($azAccount.user.name)" "Green"
    }
    catch {
        Write-ColorOutput "[ERROR] Azure CLI is not installed or not logged in. Run 'az login'" "Red"
        exit 1
    }
    
    # Check if required files exist
    $requiredFiles = @($backendFile, $varsFile)
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $terraformDir $file
        if (-not (Test-Path $filePath)) {
            Write-ColorOutput "[ERROR] Required file not found: $filePath" "Red"
            exit 1
        }
    }
    
    Write-ColorOutput "[SUCCESS] All prerequisites met" "Green"
}

function Initialize-Terraform {
    Write-ColorOutput "[INFO] Initializing Terraform..." "Blue"
    
    Set-Location $terraformDir
    
    # Initialize with backend configuration
    $initCmd = "terraform init -backend-config=$backendFile"
    Write-ColorOutput "[EXEC] $initCmd" "Yellow"
    
    Invoke-Expression $initCmd
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "[ERROR] Terraform init failed" "Red"
        exit 1
    }
    
    Write-ColorOutput "[SUCCESS] Terraform initialized" "Green"
}

function Invoke-TerraformPlan {
    Write-ColorOutput "[INFO] Running Terraform plan..." "Blue"
    
    $planFile = "tfplan-$Environment"
    $planCmd = "terraform plan -var-file=$varsFile -out=$planFile"
    
    Write-ColorOutput "[EXEC] $planCmd" "Yellow"
    Invoke-Expression $planCmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "[ERROR] Terraform plan failed" "Red"
        exit 1
    }
    
    Write-ColorOutput "[SUCCESS] Terraform plan completed. Plan saved to: $planFile" "Green"
}

function Invoke-TerraformApply {
    Write-ColorOutput "[INFO] Running Terraform apply..." "Blue"
    
    $planFile = "tfplan-$Environment"
    
    if (Test-Path $planFile) {
        if ($AutoApprove) {
            $applyCmd = "terraform apply -auto-approve $planFile"
        } else {
            $applyCmd = "terraform apply $planFile"
        }
    } else {
        if ($AutoApprove) {
            $applyCmd = "terraform apply -var-file=$varsFile -auto-approve"
        } else {
            $applyCmd = "terraform apply -var-file=$varsFile"
        }
    }
    
    Write-ColorOutput "[EXEC] $applyCmd" "Yellow"
    Invoke-Expression $applyCmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "[ERROR] Terraform apply failed" "Red"
        exit 1
    }
    
    Write-ColorOutput "[SUCCESS] Terraform apply completed" "Green"
}

function Invoke-TerraformDestroy {
    Write-ColorOutput "[WARNING] This will destroy all resources in $Environment environment" "Yellow"
    
    if (-not $AutoApprove) {
        $confirmation = Read-Host "Are you sure you want to destroy? Type 'yes' to confirm"
        if ($confirmation -ne 'yes') {
            Write-ColorOutput "[INFO] Destroy cancelled" "Blue"
            return
        }
    }
    
    $destroyCmd = if ($AutoApprove) {
        "terraform destroy -var-file=$varsFile -auto-approve"
    } else {
        "terraform destroy -var-file=$varsFile"
    }
    
    Write-ColorOutput "[EXEC] $destroyCmd" "Yellow"
    Invoke-Expression $destroyCmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "[ERROR] Terraform destroy failed" "Red"
        exit 1
    }
    
    Write-ColorOutput "[SUCCESS] Terraform destroy completed" "Green"
}

# Main execution
try {
    Write-ColorOutput "=== Microsoft Fabric Infrastructure Deployment ===" "Blue"
    Write-ColorOutput "Environment: $Environment" "Blue"
    Write-ColorOutput "Action: $Action" "Blue"
    Write-ColorOutput "Auto Approve: $AutoApprove" "Blue"
    Write-ColorOutput "===============================================" "Blue"
    
    Test-Prerequisites
    
    if (-not $SkipInit -or $Action -eq 'init') {
        Initialize-Terraform
    }
    
    switch ($Action) {
        'init' { 
            Write-ColorOutput "[SUCCESS] Initialization completed" "Green"
        }
        'plan' { 
            Invoke-TerraformPlan 
        }
        'apply' { 
            Invoke-TerraformApply 
        }
        'destroy' { 
            Invoke-TerraformDestroy 
        }
    }
    
    Write-ColorOutput "[SUCCESS] Operation completed successfully" "Green"
}
catch {
    Write-ColorOutput "[ERROR] Script execution failed: $($_.Exception.Message)" "Red"
    exit 1
}