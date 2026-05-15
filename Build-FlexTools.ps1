# ------------------------------------------------------------------------------------------------------------------------
# HERNIS FLEX Tools Installer Package Builder
# ------------------------------------------------------------------------------------------------------------------------
#
# Creates a distributable installer zip in the build folder.
#
# Usage:
#   .\Build-FlexTools.ps1
#   .\Build-FlexTools.ps1 -Clean
#   .\Build-FlexTools.ps1 -PackageName "FlexTools-installer"
#
# ------------------------------------------------------------------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OutputDirectory = "build",
    [string]$PackageName = "FlexTools-installer",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
$buildPath = Join-Path $scriptRoot $OutputDirectory
$stagingPath = Join-Path $buildPath "staging"

# Files required for running Install-FlexTools.ps1 from the package.
$filesToPackage = @(
    "Install-FlexTools.ps1",
    "Uninstall-FlexTools.ps1",
    "FlexTools.psd1",
    "FlexTools.psm1",
    "RegistryConfiguration.psd1",
    "RegistryConfiguration.psm1",
    "XmlWatchdogConfiguration.psd1",
    "XmlWatchdogConfiguration.psm1",
    "README.md"
)

function Get-ModuleVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    if (-not (Test-Path $ManifestPath)) {
        return "0.0.0"
    }

    try {
        $manifest = Import-PowerShellDataFile -Path $ManifestPath
        if ($manifest.ModuleVersion) {
            return [string]$manifest.ModuleVersion
        }
    }
    catch {
        Write-Warning "Could not read module version from manifest. Falling back to 0.0.0."
    }

    return "0.0.0"
}

$manifestPath = Join-Path $scriptRoot "FlexTools.psd1"
$moduleVersion = Get-ModuleVersion -ManifestPath $manifestPath
$zipFileName = "$PackageName-$moduleVersion.zip"
$zipPath = Join-Path $buildPath $zipFileName

$missingFiles = @()
foreach ($file in $filesToPackage) {
    $fullPath = Join-Path $scriptRoot $file
    if (-not (Test-Path $fullPath)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    throw "Cannot build installer package. Missing files: $($missingFiles -join ', ')"
}

if ($Clean -and (Test-Path $buildPath)) {
    if ($PSCmdlet.ShouldProcess($buildPath, "Remove build directory")) {
        Remove-Item -Path $buildPath -Recurse -Force
    }
}

if (-not (Test-Path $buildPath)) {
    if ($PSCmdlet.ShouldProcess($buildPath, "Create build directory")) {
        New-Item -Path $buildPath -ItemType Directory -Force | Out-Null
    }
}

if (Test-Path $stagingPath) {
    if ($PSCmdlet.ShouldProcess($stagingPath, "Remove existing staging directory")) {
        Remove-Item -Path $stagingPath -Recurse -Force
    }
}

if ($PSCmdlet.ShouldProcess($stagingPath, "Create staging directory")) {
    New-Item -Path $stagingPath -ItemType Directory -Force | Out-Null
}

foreach ($file in $filesToPackage) {
    $source = Join-Path $scriptRoot $file
    $destination = Join-Path $stagingPath $file

    if ($PSCmdlet.ShouldProcess($destination, "Copy $file to staging")) {
        Copy-Item -Path $source -Destination $destination -Force
    }
}

if (Test-Path $zipPath) {
    if ($PSCmdlet.ShouldProcess($zipPath, "Remove existing zip")) {
        Remove-Item -Path $zipPath -Force
    }
}

if ($PSCmdlet.ShouldProcess($zipPath, "Create installer zip")) {
    Compress-Archive -Path (Join-Path $stagingPath "*") -DestinationPath $zipPath -CompressionLevel Optimal -Force
}

if (Test-Path $stagingPath) {
    if ($PSCmdlet.ShouldProcess($stagingPath, "Remove staging directory")) {
        Remove-Item -Path $stagingPath -Recurse -Force
    }
}

Write-Host "Created installer package: $zipPath" -ForegroundColor Green
