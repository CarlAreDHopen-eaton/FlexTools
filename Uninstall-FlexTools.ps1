# ------------------------------------------------------------------------------------------------------------------------
# HERNIS FLEX Tools PowerShell Module Uninstaller
# ------------------------------------------------------------------------------------------------------------------------
#
# This script safely removes the FlexTools PowerShell module from the system.
#
# Usage: .\Uninstall-FlexTools.ps1 [-Force] [-WhatIf]
#   -Force: Skip confirmation prompts
#   -WhatIf: Show what would be uninstalled without actually uninstalling
#
# ------------------------------------------------------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    [switch]$WhatIf
)

# Configuration
$ModuleName = "FlexTools"
$TargetBasePath = "$env:ProgramFiles\WindowsPowerShell\Modules"
$TargetPath = Join-Path $TargetBasePath $ModuleName

# Function to get the current installed version
function Get-InstalledVersion {
    try {
        $moduleFile = Join-Path $TargetPath "$ModuleName.psm1"
        
        if (Test-Path $moduleFile) {
            $content = Get-Content $moduleFile -Raw
            if ($content -match '\$FlexToolsVersion\s*=\s*["\']([^"\']+)["\']') {
                return $matches[1]
            }
        }
        
        return "Unknown"
    }
    catch {
        return "Unknown"
    }
}

# Main uninstallation logic
Write-Host "HERNIS FLEX Tools PowerShell Module Uninstaller" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Check if module is installed
if (-not (Test-Path $TargetPath)) {
    Write-Host "FlexTools module is not installed at: $TargetPath" -ForegroundColor Yellow
    exit 0
}

$installedVersion = Get-InstalledVersion
Write-Host "Found FlexTools module version: $installedVersion" -ForegroundColor Green
Write-Host "Installation path: $TargetPath" -ForegroundColor Green
Write-Host ""

# Check if module is currently loaded
$loadedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
if ($loadedModule) {
    Write-Host "WARNING: The FlexTools module is currently loaded in this PowerShell session." -ForegroundColor Yellow
    Write-Host "You may need to restart PowerShell after uninstallation." -ForegroundColor Yellow
    Write-Host ""
}

# Confirmation
if (-not $Force) {
    $confirmation = Read-Host "Are you sure you want to uninstall FlexTools module? (yes/no)"
    if ($confirmation -notmatch '^(yes|y)$') {
        Write-Host "Uninstallation cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Check for administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "Administrative privileges may be required for uninstalling from $TargetPath"
}

# Uninstall the module
Write-Host "Uninstalling FlexTools module..." -ForegroundColor Yellow

try {
    if ($PSCmdlet.ShouldProcess($TargetPath, "Remove FlexTools module")) {
        # Remove the module directory
        Remove-Item -Path $TargetPath -Recurse -Force
        
        # Clean up any backup directories
        $backupPattern = "$TargetPath.backup_*"
        $parentPath = Split-Path $TargetPath
        $moduleNamePattern = "$(Split-Path $TargetPath -Leaf).backup_*"
        
        $backupDirs = Get-ChildItem -Path $parentPath -Directory -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like $moduleNamePattern }
        
        if ($backupDirs) {
            Write-Host "Cleaning up backup directories..." -ForegroundColor Yellow
            foreach ($backupDir in $backupDirs) {
                try {
                    Remove-Item -Path $backupDir.FullName -Recurse -Force
                    Write-Host "Removed backup: $($backupDir.Name)" -ForegroundColor Gray
                }
                catch {
                    Write-Warning "Could not remove backup directory: $($backupDir.Name)"
                }
            }
        }
        
        Write-Host ""
        Write-Host "FlexTools module has been successfully uninstalled!" -ForegroundColor Green
        Write-Host ""
        
        if ($loadedModule) {
            Write-Host "Note: The module is still loaded in the current session." -ForegroundColor Yellow
            Write-Host "Restart PowerShell to complete the uninstallation." -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "Uninstallation failed: $_"
    Write-Host ""
    Write-Host "You may need to:" -ForegroundColor Yellow
    Write-Host "1. Run as Administrator" -ForegroundColor White
    Write-Host "2. Close any PowerShell sessions that have the module loaded" -ForegroundColor White
    Write-Host "3. Manually remove the directory: $TargetPath" -ForegroundColor White
    exit 1
}
