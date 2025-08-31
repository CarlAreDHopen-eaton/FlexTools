class RegistryConfiguration {
    static [string] $WatchdogRegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog'
    static [string] $WatchdogCommandPath = 'HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog\Command'
    static [string] $WatchdogInstalledPath = 'HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog\Installed'

    # Constructor
    RegistryConfiguration() {}

    # Static methods for common registry operations
    static [bool] EnsureKeyExists([string]$keyPath) {
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

    # Get registry settings for a module
    static [int] GetModuleCount() {
        try {
            return (Get-ItemPropertyValue -Path [RegistryConfiguration]::WatchdogInstalledPath -Name Count)
        }
        catch {
            Write-Warning "Failed to get module count from registry"
            return 0
        }
    }

    # Get module settings by number and prefix
    static [string] GetModuleStringSetting([int]$moduleNumber, [string]$settingPrefix, [string]$defaultValue) {
        $keyPath = [RegistryConfiguration]::WatchdogInstalledPath
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

    static [int] GetModuleIntSetting([int]$moduleNumber, [string]$settingPrefix, [int]$defaultValue) {
        $keyPath = [RegistryConfiguration]::WatchdogInstalledPath
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

    static [bool] SetModuleIntSetting([int]$moduleNumber, [string]$settingPrefix, [int]$value) {
        if (-not [RegistryConfiguration]::EnsureKeyExists([RegistryConfiguration]::WatchdogCommandPath)) {
            return $false
        }

        $valueName = "$settingPrefix#$moduleNumber"
        try {
            New-ItemProperty -Path [RegistryConfiguration]::WatchdogCommandPath -Name $valueName -Value $value -PropertyType DWORD -Force | Out-Null
            return $true
        }
        catch {
            Write-Warning "Failed to set int setting $valueName"
            return $false
        }
    }

    # Module command operations
    static [bool] SetModuleCommand([int]$moduleNumber, [int]$commandId) {
        if (-not [RegistryConfiguration]::EnsureKeyExists([RegistryConfiguration]::WatchdogCommandPath)) {
            return $false
        }

        $valueName = "Command#$moduleNumber"
        try {
            New-ItemProperty -Path [RegistryConfiguration]::WatchdogCommandPath -Name $valueName -Value $commandId -PropertyType DWORD -Force | Out-Null
            return $true
        }
        catch {
            Write-Warning "Failed to set module command $valueName"
            return $false
        }
    }

    # Debug settings operations
    static [bool] SetHeapDebugging([string]$moduleName, [string]$moduleFileName, [bool]$enabled) {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$moduleFileName"
        
        if ($enabled) {
            # Flags for heap debugging features
            $debugFlags = "0x02109870" # Combined debugging flags
            
            if (-not [RegistryConfiguration]::EnsureKeyExists($registryPath)) {
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
            # Disable debugging by removing the key
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

    static [bool] SetCrashDumpSettings([string]$moduleName, [string]$moduleFileName, [bool]$enabled, [int]$dumpCount = 5) {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\$moduleFileName"
        $dumpPath = "C:\Dumps\$moduleName"

        if ($enabled) {
            if (-not [RegistryConfiguration]::EnsureKeyExists($registryPath)) {
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
