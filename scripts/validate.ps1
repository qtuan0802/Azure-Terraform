#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validate Microsoft Fabric Infrastructure Configuration

.DESCRIPTION
    This script validates the Terraform configuration and deployment
    for Microsoft Fabric infrastructure.

.PARAMETER Environment
    Target environment (dev, staging, prod)

.EXAMPLE
    .\validate.ps1 -Environment dev
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment
)

# Configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootPath = Split-Path -Parent $scriptPath
$terraformDir = $rootPath
$varsFile = "$Environment.tfvars"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    $colors = @{
        'Green' = 'Green'
        'Red' = 'Red'
        'Yellow' = 'Yellow'
        'Blue' = 'Blue'
    }
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Test-TerraformValidation {
    Write-ColorOutput "[INFO] Running Terraform validation..." "Blue"
    
    Set-Location $terraformDir
    
    # Format check
    terraform fmt -check -recursive
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "[WARNING] Terraform files are not properly formatted" "Yellow"
        Write-ColorOutput "[INFO] Running terraform fmt..." "Blue"
        terraform fmt -recursive
    } else {
        Write-ColorOutput "[SUCCESS] Terraform files are properly formatted" "Green"
    }
    
    # Validate configuration
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "[ERROR] Terraform validation failed" "Red"
        return $false
    }
    
    Write-ColorOutput "[SUCCESS] Terraform validation passed" "Green"
    return $true
}

function Test-VariablesFile {
    Write-ColorOutput "[INFO] Validating variables file..." "Blue"
    
    $varsPath = Join-Path $terraformDir $varsFile
    if (-not (Test-Path $varsPath)) {
        Write-ColorOutput "[ERROR] Variables file not found: $varsPath" "Red"
        return $false
    }
    
    # Check for required variables
    $content = Get-Content $varsPath -Raw
    $requiredVars = @('environment', 'location', 'fabric_capacity_id')
    
    foreach ($var in $requiredVars) {
        if ($content -notmatch $var) {
            Write-ColorOutput "[ERROR] Required variable '$var' not found in $varsFile" "Red"
            return $false
        }
    }
    
    Write-ColorOutput "[SUCCESS] Variables file validation passed" "Green"
    return $true
}

function Test-SecurityCompliance {
    Write-ColorOutput "[INFO] Checking security compliance..." "Blue"
    
    $issues = @()
    
    # Check for sensitive values in .tfvars files
    $varsContent = Get-Content (Join-Path $terraformDir $varsFile) -Raw
    
    # Check for hardcoded secrets
    $secretPatterns = @(
        'password\s*=\s*"[^"]+"',
        'secret\s*=\s*"[^"]+"',
        'key\s*=\s*"[^"]+"',
        'token\s*=\s*"[^"]+"'
    )
    
    foreach ($pattern in $secretPatterns) {
        if ($varsContent -match $pattern) {
            $issues += "Potential hardcoded secret found in $varsFile"
        }
    }
    
    # Check storage account configuration
    if ($varsContent -match 'https_traffic_only_enabled\s*=\s*false') {
        $issues += "Storage account should enforce HTTPS traffic only"
    }
    
    if ($varsContent -match 'public_network_access_enabled\s*=\s*true' -and $Environment -eq 'prod') {
        $issues += "Production environment should restrict public network access"
    }
    
    if ($issues.Count -gt 0) {
        Write-ColorOutput "[WARNING] Security compliance issues found:" "Yellow"
        foreach ($issue in $issues) {
            Write-ColorOutput "  - $issue" "Yellow"
        }
        return $false
    }
    
    Write-ColorOutput "[SUCCESS] Security compliance check passed" "Green"
    return $true
}

function Test-ResourceNaming {
    Write-ColorOutput "[INFO] Validating resource naming conventions..." "Blue"
    
    # Check main.tf for resource naming patterns
    $mainTfPath = Join-Path $terraformDir "main.tf"
    if (Test-Path $mainTfPath) {
        $content = Get-Content $mainTfPath -Raw
        
        # Check if resources follow naming convention
        if ($content -notmatch 'name\s*=\s*"[a-z]+-[a-z]+-\$\{var\.environment\}') {
            Write-ColorOutput "[WARNING] Resources should follow naming convention: prefix-service-environment" "Yellow"
        }
    }
    
    Write-ColorOutput "[SUCCESS] Resource naming validation completed" "Green"
    return $true
}

# Main execution
try {
    Write-ColorOutput "=== Microsoft Fabric Infrastructure Validation ===" "Blue"
    Write-ColorOutput "Environment: $Environment" "Blue"
    Write-ColorOutput "================================================" "Blue"
    
    $validationResults = @()
    $validationResults += Test-TerraformValidation
    $validationResults += Test-VariablesFile
    $validationResults += Test-SecurityCompliance
    $validationResults += Test-ResourceNaming
    
    $failedValidations = $validationResults | Where-Object { $_ -eq $false }
    
    if ($failedValidations.Count -gt 0) {
        Write-ColorOutput "[ERROR] Validation completed with $($failedValidations.Count) failures" "Red"
        exit 1
    } else {
        Write-ColorOutput "[SUCCESS] All validations passed" "Green"
        exit 0
    }
}
catch {
    Write-ColorOutput "[ERROR] Validation script failed: $($_.Exception.Message)" "Red"
    exit 1
}