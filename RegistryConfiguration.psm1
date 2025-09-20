class RegistryConfiguration
{
    [string] $RootKey
    [string] $BaseRegistryPath
    [string] $WatchdogRegistryPath
    [string] $WatchdogCommandPath
    [string] $WatchdogInstalledPath

    RegistryConfiguration()
    {
        $this.ResetToProductionPaths()
    }

    [void] SetupForTesting()
    {
        $this.RootKey = 'HKCU:'
        $this.SetBasePath('HKCU:\SOFTWARE\WOW6432Node\Test Hernis Scan Systems')
    }

    [void] SetBasePath([string]$basePath)
    {
        $this.BaseRegistryPath = $basePath
        $this.WatchdogRegistryPath = Join-Path $basePath 'WatchDog'
        $this.WatchdogCommandPath = Join-Path ($this.WatchdogRegistryPath) 'Command'
        $this.WatchdogInstalledPath = Join-Path ($this.WatchdogRegistryPath) 'Installed'
    }

    [void] ResetToProductionPaths()
    {
        $this.RootKey = 'HKLM:'
        $this.SetBasePath('HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems')
    }

    [bool] EnsureKeyExists([string]$keyPath)
    {
        if (-not (Test-Path $keyPath)) {
            try {
                New-Item -Path $keyPath -Force | Out-Null
                return $true
            }
            catch {
                Write-Warning "Failed to create registry key: $keyPath"
                return $false
            }
        }
        return $true
    }

    [int] GetModuleCount()
    {
        try {
            return (Get-ItemPropertyValue -Path $this.WatchdogInstalledPath -Name Count)
        }
        catch {
            Write-Warning "Failed to get module count from registry"
            return 0
        }
    }

    [string] GetModuleStringSetting([int]$moduleNumber, [string]$settingPrefix, [string]$defaultValue)
    {
        $keyPath = $this.WatchdogInstalledPath
        $returnValue = $defaultValue
        if (Test-Path -Path $keyPath) {
            $valueName = "$settingPrefix#$moduleNumber"
            try {
                $returnValue = (Get-ItemProperty -Path $keyPath | Select-Object $valueName -ExpandProperty $valueName)
            }
            catch {
                Write-Verbose "Failed to get string setting $valueName, using default value"
            }
        }
        return $returnValue
    }

    [int] GetModuleIntSetting([int]$moduleNumber, [string]$settingPrefix, [int]$defaultValue)
    {
        $keyPath = $this.WatchdogInstalledPath
        $returnValue = $defaultValue
        if (Test-Path -Path $keyPath) {
            $valueName = "$settingPrefix#$moduleNumber"
            try {
                $returnValue = (Get-ItemProperty -Path $keyPath | Select-Object $valueName -ExpandProperty $valueName)
            }
            catch {
                Write-Verbose "Failed to get int setting $valueName, using default value"
            }
        }
        return $returnValue
    }

    [bool] SetModuleIntSetting([int]$moduleNumber, [string]$settingPrefix, [int]$value)
    {
        if (-not $this.EnsureKeyExists($this.WatchdogCommandPath)) {
            return $false
        }

        $valueName = "$settingPrefix#$moduleNumber"
        try {
            New-ItemProperty -Path $this.WatchdogCommandPath -Name $valueName -Value $value -PropertyType DWORD -Force | Out-Null
            return $true
        }
        catch {
            Write-Warning "Failed to set int setting $valueName"
            return $false
        }
    }

    [bool] SetModuleCommand([int]$moduleNumber, [int]$commandId)
    {
        if (-not $this.EnsureKeyExists($this.WatchdogCommandPath)) {
            return $false
        }

        $valueName = "Command#$moduleNumber"
        try {
            New-ItemProperty -Path $this.WatchdogCommandPath -Name $valueName -Value $commandId -PropertyType DWORD -Force | Out-Null
            return $true
        }
        catch {
            Write-Warning "Failed to set module command $valueName"
            return $false
        }
    }

    [bool] SetHeapDebugging([string]$moduleName, [string]$moduleFileName, [bool]$enabled)
    {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$moduleFileName"
        
        if ($enabled) {
            $debugFlags = "0x02109870"
            
            if (-not $this.EnsureKeyExists($registryPath)) {
                return $false
            }

            try {
                New-ItemProperty -Path $registryPath -Name "GlobalFlag" -Value $debugFlags -PropertyType STRING -Force | Out-Null
                return $true
            }
            catch {
                Write-Warning "Failed to enable heap debugging for $moduleName"
                return $false
            }
        }
        else {
            if (Test-Path $registryPath) {
                try {
                    Remove-Item -Path $registryPath -Force | Out-Null
                    return $true
                }
                catch {
                    Write-Warning "Failed to disable heap debugging for $moduleName"
                    return $false
                }
            }
            return $true
        }
    }

    [bool] SetCrashDumpSettings([string]$moduleName, [string]$moduleFileName, [bool]$enabled, [int]$dumpCount = 5)
    {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\$moduleFileName"
        $dumpPath = "C:\Dumps\$moduleName"

        if ($enabled) {
            if (-not $this.EnsureKeyExists($registryPath)) {
                return $false
            }

            try {
                New-ItemProperty -Path $registryPath -Name "DumpCount" -Value $dumpCount -PropertyType DWORD -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name "DumpType" -Value 2 -PropertyType DWORD -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name "DumpFolder" -Value $dumpPath -PropertyType STRING -Force | Out-Null
                return $true
            }
            catch {
                Write-Warning "Failed to enable crash dump settings for $moduleName"
                return $false
            }
        }
        else {
            if (Test-Path $registryPath) {
                try {
                    Remove-Item -Path $registryPath -Force | Out-Null
                    return $true
                }
                catch {
                    Write-Warning "Failed to disable crash dump settings for $moduleName"
                    return $false
                }
            }
            return $true
        }
    }
}

# Export the class
Export-ModuleMember -Function * -Variable *
