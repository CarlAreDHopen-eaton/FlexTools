# ------------------------------------------------------------------------------------------------------------------------
# HERNIS FLEX Tools PowerShell Module Installer
# ------------------------------------------------------------------------------------------------------------------------
#
# This script installs the FlexTools PowerShell module with version checking and safe installation practices.
# It will check for existing installations and warn before downgrades.
#
# Usage: .\Install-FlexTools.ps1 [-Force] [-WhatIf]
#   -Force: Skip version checks and install anyway
#   -WhatIf: Show what would be installed without actually installing
#
# ------------------------------------------------------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

# Configuration
$ModuleName = "FlexTools"
$script:SourcePath = $PSScriptRoot

# Determine the correct module path based on PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PowerShell 6+ (Core/7+) - use system-wide path for consistency
    $TargetBasePath = "$env:SystemRoot\System32\PowerShell\v1.0\Modules"
} else {
    # Windows PowerShell 5.1 and earlier - use system-wide path as documented
    $TargetBasePath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules"
}
$TargetPath = Join-Path $TargetBasePath $ModuleName

# Required files for the module
$RequiredFiles = @(
    "FlexTools.psm1",
    "RegistryConfiguration.psm1", 
    "XmlWatchdogConfiguration.psm1"
)

# Optional files that should be copied if they exist
$OptionalFiles = @(
    "README.md"
)

# Function to compare version strings
function Compare-Version {
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    try {
        $v1 = [version]$Version1
        $v2 = [version]$Version2
        return $v1.CompareTo($v2)
    }
    catch {
        # Fallback to string comparison if version parsing fails
        return [string]::Compare($Version1, $Version2, $true)
    }
}

# Function to get the current installed version
function Get-InstalledVersion {
    try {
        # Check if module is already imported
        $loadedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        if ($loadedModule) {
            # Try to get version from loaded module
            $version = & { Get-FlexToolsVersion } 2>$null
            if ($version) {
                return $version
            }
        }

        # Check if module exists in modules path
        $moduleManifest = Join-Path $TargetPath "$ModuleName.psd1"
        $moduleFile = Join-Path $TargetPath "$ModuleName.psm1"
        
        if (Test-Path $moduleFile) {
            # Try to extract version from the psm1 file
            $content = Get-Content $moduleFile -Raw
            if ($content -match '\$FlexToolsVersion\s*=\s*["\'']([\d\.]+)["\'']*') {
                return $matches[1]
            }
        }
        
        return $null
    }
    catch {
        Write-Warning "Could not determine installed version: $_"
        return $null
    }
}

# Function to get the version from source files
function Get-SourceVersion {
    try {
        $sourceFile = Join-Path $script:SourcePath "$ModuleName.psm1"
        if (Test-Path $sourceFile) {
            $content = Get-Content $sourceFile -Raw
            if ($content -match '\$FlexToolsVersion\s*=\s*["\'']([\d\.]+)["\'']*') {
                return $matches[1]
            }
        }
        return $null
    }
    catch {
        Write-Warning "Could not determine source version: $_"
        return $null
    }
}

# Function to validate source files
function Test-SourceFiles {
    $missingFiles = @()
    
    foreach ($file in $RequiredFiles) {
        $filePath = Join-Path $script:SourcePath $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Error "Missing required files: $($missingFiles -join ', ')"
        return $false
    }
    
    return $true
}

# Function to backup existing installation
function Backup-ExistingInstallation {
    if (Test-Path $TargetPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$TargetPath.backup_$timestamp"
        
        Write-Host "Creating backup of existing installation at: $backupPath" -ForegroundColor Yellow
        
        if ($PSCmdlet.ShouldProcess($TargetPath, "Backup to $backupPath")) {
            try {
                Copy-Item -Path $TargetPath -Destination $backupPath -Recurse -Force
                Write-Host "Backup created successfully" -ForegroundColor Green
                return $backupPath
            }
            catch {
                Write-Warning "Failed to create backup: $_"
                return $null
            }
        }
    }
    return $null
}

# Function to install the module
function Install-Module {
    param($BackupPath)
    
    try {
        # Create target directory if it doesn't exist
        if (-not (Test-Path $TargetBasePath)) {
            if ($PSCmdlet.ShouldProcess($TargetBasePath, "Create modules directory")) {
                New-Item -Path $TargetBasePath -ItemType Directory -Force | Out-Null
            }
        }
        
        if (-not (Test-Path $TargetPath)) {
            if ($PSCmdlet.ShouldProcess($TargetPath, "Create module directory")) {
                New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
            }
        }
        
        # Copy required files
        foreach ($file in $RequiredFiles) {
            $sourcePath = Join-Path $script:SourcePath $file
            $destPath = Join-Path $TargetPath $file
            
            if ($PSCmdlet.ShouldProcess($destPath, "Copy $file from source directory")) {
                Copy-Item -Path $sourcePath -Destination $destPath -Force
                Write-Host "Copied: $file" -ForegroundColor Green
            }
        }
        
        # Copy optional files if they exist
        foreach ($file in $OptionalFiles) {
            $sourcePath = Join-Path $script:SourcePath $file
            if (Test-Path $sourcePath) {
                $destPath = Join-Path $TargetPath $file
                
                if ($PSCmdlet.ShouldProcess($destPath, "Copy $file from source directory")) {
                    Copy-Item -Path $sourcePath -Destination $destPath -Force
                    Write-Host "Copied: $file" -ForegroundColor Green
                }
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Installation failed: $_"
        
        # Attempt to restore backup if installation failed
        if ($BackupPath -and (Test-Path $BackupPath)) {
            Write-Host "Attempting to restore backup..." -ForegroundColor Yellow
            try {
                if (Test-Path $TargetPath) {
                    Remove-Item -Path $TargetPath -Recurse -Force
                }
                Move-Item -Path $BackupPath -Destination $TargetPath
                Write-Host "Backup restored successfully" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to restore backup: $_"
            }
        }
        
        return $false
    }
}

# Main installation logic
Write-Host "HERNIS FLEX Tools PowerShell Module Installer" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Validate source files
Write-Host "Validating source files..." -ForegroundColor Yellow
if (-not (Test-SourceFiles)) {
    exit 1
}

# Get versions
$sourceVersion = Get-SourceVersion
$installedVersion = Get-InstalledVersion

Write-Host "Source version: $sourceVersion" -ForegroundColor Green
if ($installedVersion) {
    Write-Host "Installed version: $installedVersion" -ForegroundColor Green
} else {
    Write-Host "No existing installation found" -ForegroundColor Yellow
}
Write-Host ""

# Version comparison and user confirmation
if ($installedVersion -and $sourceVersion) {
    $versionComparison = Compare-Version -Version1 $sourceVersion -Version2 $installedVersion
    
    if ($versionComparison -lt 0 -and -not $Force) {
        Write-Host "WARNING: You are about to downgrade from version $installedVersion to $sourceVersion" -ForegroundColor Red
        Write-Host "This may cause compatibility issues or loss of functionality." -ForegroundColor Red
        Write-Host ""
        
        $confirmation = Read-Host "Do you want to continue with the downgrade? (yes/no)"
        if ($confirmation -notmatch '^(yes|y)$') {
            Write-Host "Installation cancelled by user" -ForegroundColor Yellow
            exit 0
        }
    }
    elseif ($versionComparison -eq 0 -and -not $Force) {
        Write-Host "The same version ($sourceVersion) is already installed." -ForegroundColor Yellow
        $confirmation = Read-Host "Do you want to reinstall? (yes/no)"
        if ($confirmation -notmatch '^(yes|y)$') {
            Write-Host "Installation cancelled by user" -ForegroundColor Yellow
            exit 0
        }
    }
    elseif ($versionComparison -gt 0) {
        Write-Host "Upgrading from version $installedVersion to $sourceVersion" -ForegroundColor Green
    }
}

# Check for administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "Administrative privileges are recommended for installing to $TargetBasePath"
    Write-Host "Consider running as Administrator or the installation may fail." -ForegroundColor Yellow
    
    $confirmation = Read-Host "Do you want to continue anyway? (yes/no)"
    if ($confirmation -notmatch '^(yes|y)$') {
        Write-Host "Installation cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Backup existing installation
$backupPath = $null
if (Test-Path $TargetPath) {
    $backupPath = Backup-ExistingInstallation
}

# Install the module
Write-Host "Installing FlexTools module..." -ForegroundColor Yellow
if (Install-Module -BackupPath $backupPath) {
    Write-Host ""
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The FlexTools module has been installed to: $TargetPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "The module is now available. To use it:" -ForegroundColor Cyan
    Write-Host "1. Open a new PowerShell session (or restart your current one)" -ForegroundColor White
    Write-Host "2. Run FlexTools commands directly (no import needed)" -ForegroundColor White
    Write-Host "3. Get available commands: Get-Command -Module FlexTools" -ForegroundColor White
    Write-Host "4. Check version: Get-FlexToolsVersion" -ForegroundColor White
    Write-Host ""
    
    # Clean up old backups (keep only the 3 most recent)
    $backupPattern = "$TargetPath.backup_*"
    $existingBackups = Get-ChildItem -Path (Split-Path $TargetPath) -Directory | 
        Where-Object { $_.Name -like "$(Split-Path $TargetPath -Leaf).backup_*" } |
        Sort-Object CreationTime -Descending
    
    if ($existingBackups.Count -gt 3) {
        $oldBackups = $existingBackups | Select-Object -Skip 3
        foreach ($oldBackup in $oldBackups) {
            try {
                Remove-Item -Path $oldBackup.FullName -Recurse -Force
                Write-Host "Cleaned up old backup: $($oldBackup.Name)" -ForegroundColor Gray
            }
            catch {
                Write-Warning "Could not clean up old backup: $($oldBackup.Name)"
            }
        }
    }
} else {
    Write-Host ""
    Write-Host "Installation failed!" -ForegroundColor Red
    exit 1
}
