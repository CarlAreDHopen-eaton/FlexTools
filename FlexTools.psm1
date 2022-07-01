# ------------------------------------------------------------------------------------------------------------------------
# HERNIS FLEX Tools PowerShell Module
# ------------------------------------------------------------------------------------------------------------------------
#
# Version 1.0 (19/04/2022)
# ------------------------------------------------------------------------------------------------------------------------
#    - Support for starting the HERNIS FLEX Watchdog (Start-FlexWatchdog)
#    - Support for stopping the HERNIS FLEX Watchdog (Stop-FlexWatchdog)
#    - Support for getting the HERNIS FLEX Watchdog module list (Get-FlexModuleList)
#    - Support for getting single HERNIS FLEX Watchdog modules (Get-FlexModuleByName)
#    - Support for getting the HERNIS FLEX Watchdog (Get-FlexWatchdog)
#    - Support for checking if the HERNIS FLEX Watchdog is running (Get-FlexWatchdogRunning)
#    - Support for starting HERNIS FLEX Watchdog Modules (Start-FlexModule)
#    - Support for stopping HERNIS FLEX Watchdog Modules (Stop-FlexModule)
#
# Version 1.1 (27/04/2022)
# ------------------------------------------------------------------------------------------------------------------------
#   - Support for setting startup mode (Set-FlexModuleStartup)
#
# Version 1.2 (02/05/2022)
# ------------------------------------------------------------------------------------------------------------------------
#   - Support for checking if the Windows SNMP service is responding (Test-WindowsSnmp)
#   - Support for checking if the LSI RAID SNMP extension agent is responding (Test-LsiRaidSnmp)
#   - Support for info from the LSI RAID SNMP extension agent (Get-LsiRaidInfoFromSnmp)
#
# Installation:
# ------------------------------------------------------------------------------------------------------------------------
#   - Open the following folder: C:\Windows\System32\WindowsPowerShell\v1.0\Modules
#   - Make a folder named FlexTools
#   - Copy FlexTools.psm1 to the FlexTools folder
#   - Start a new PowerShell terminal window.
#   - Use the exported functions.
#
# ------------------------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------
# Classes
# ------------------------------------------------------------------------------------------------------------------------
class FlexModule
{
    [string]$ModulePath
    [string]$ModuleName
    [int]$ModuleNumber
    [bool]$ModuleRunning

    ReportModule()
    {
        Write-Host Module Info:
        Write-Host " Running   = "$this.IsRunning()
        Write-Host " Number    = "$this.ModuleNumber
        Write-Host " Path      = "$this.ModulePath
        Write-Host " Status    = "$this.GetStatus();
        Write-Host " Name      = "$this.ModuleName;
        Write-Host " ProcessID = "$this.GetProcessId();
        Write-Host " Startup   = "$this.GetStartup();
    }

    [bool]Initialize([int]$ModuleNo)
    {
        $this.ModuleNumber = $moduleNo;
        $this.ModulePath = $this.GetPath();
        $this.ModuleName = $this.GetModuleName();
        $this.ModuleRunning = $this.IsRunning();
        # TODO Validate is this is a valid module before returning true.
        return $true;
    }

    hidden SetWatchdogCommand([int]$commandId)
    {
        #$IsRunning = Get-FlexWatchdogInstalled
        $Watchdog = Get-FlexWatchdog
        if ($false -eq $Watchdog.Installed())
        {
            Write-Warning "The HERNIS Watchdog is not installed, command aborted"
            return;
        }
        if ($false -eq $Watchdog.Running())
        {
            Write-Warning "The HERNIS Watchdog is not running, command aborted"
            return;
        }

        # Set variables to indicate value and key to set
        $RegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog\Command'
        $Name         = "Command#" + $this.ModuleNumber
        $Value        = $commandId
        # Create the key if it does not exist
        If (-NOT (Test-Path $RegistryPath)) {
          New-Item -Path $RegistryPath -Force | Out-Null
        }  
        # Now set the value
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force 
    }

    hidden [bool]SetWatchdogIntSetting([string]$SettingPrefix, [int]$Value)
    {
        $Watchdog = Get-FlexWatchdog
        if ($false -eq $Watchdog.Installed())
        {
            Write-Warning "The HERNIS Watchdog is not installed, command aborted"
            return $false;
        }

        # Set variables to indicate value and key to set
        $RegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog\Command'
        $ValueName = "$SettingPrefix#" + $this.ModuleNumber;
        
        # Create the key if it does not exist
        If (-NOT (Test-Path $RegistryPath)) {
          New-Item -Path $RegistryPath -Force | Out-Null
        }  
        If (-NOT (Test-Path $RegistryPath)) {
            # Return false if the registry path is still not there.
            return $false;
        }  
  
        # Now set the value
        New-ItemProperty -Path $RegistryPath -Name $ValueName -Value $Value -PropertyType DWORD -Force 
    
        return $true
    }

    hidden [int]GetWatchdogIntSetting([string]$SettingPrefix, [int]$DefaultValue)
    {
        $KeyPath = "HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog\Installed";
        $ReturnValue = $DefaultValue;
        $KeyPathExists = Test-Path -Path $KeyPath
        if ($true -eq $KeyPathExists)
        {
            $ValueName = "$SettingPrefix#" + $this.ModuleNumber;
            $ReturnValue = (Get-ItemProperty -Path $KeyPath | Select-Object $ValueName -ExpandProperty $ValueName);
        }
        return $ReturnValue;
    }

    hidden [string]GetWatchdogStringSetting([string]$SettingPrefix, [string]$DefaultValue)
    {
        $KeyPath = "HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog\Installed";
        $ReturnValue = $DefaultValue;
        $KeyPathExists = Test-Path -Path $KeyPath
        if ($true -eq $KeyPathExists)
        {
            $ValueName = "$SettingPrefix#" + $this.ModuleNumber;
            $ReturnValue = (Get-ItemProperty -Path $KeyPath | Select-Object $ValueName -ExpandProperty $ValueName);
        }
        return $ReturnValue;
    }

    hidden [string]GetModuleName()
    {
      $path = $this.GetPath();
      $filepath = Get-ChildItem $path
      return $filepath.BaseName
    }


    Stop()
    {
        Write-Host Stopping $this.ModuleName
        $this.SetWatchdogCommand(4);

    }

    StartManually()
    {
        if ($this.IsRunning() -eq $false)
        {
            Write-Host Starting $this.ModuleName
            $this.SetWatchdogCommand(1);
        }
        else
        {
            Write-Host The $this.ModuleName is already started.
        }
    }

    Start()
    {        
        if ($this.IsRunning() -eq $false)
        {
            if ($this.GetStartup() -eq 0)
            {
                Write-Host The $this.ModuleName is configured for manual startup, Use the StartManually function to start the module.
                return;
            }
            Write-Host Starting $this.ModuleName
            $this.SetWatchdogCommand(1);
        }
        else
        {
            Write-Host The $this.ModuleName is already started.
        }
    }

    [int]GetProcessId()
    {
        $processId = $this.GetWatchdogIntSetting("Process" , 0);
        return $processId;
    }

    [int]GetStatus()
    {
        $status = $this.GetWatchdogIntSetting("Status", 0);
        return $status;
    }

    [int]GetStartup()
    {
        $status = $this.GetWatchdogIntSetting("Startup", 0);
        return $status;
    }

    [bool]SetStartup([bool]$AutomaticStartup)
    {
        if ($true -eq $AutomaticStartup)
        {
            $status = $this.SetWatchdogIntSetting("Startup", 1);
            return $status;
        }
        $status = $this.SetWatchdogIntSetting("Startup", 0);
        return $status;
    }

    [string]GetPath()
    {
        $path = $this.GetWatchdogStringSetting("Path", "");
        return $path;
    }

    [bool]IsRunning()
    {
        $processId = $this.GetProcessId()
        if ($processId -eq 0)
        {
            # No process ID present, the HERNIS FLEX Watchdog has not started the module process.
            return $false;
        }
        else
        {
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
            if ($null -eq $process)
            {                
                # No process with this ID, the HERNIS FLEX Watchdog likely terminated improperly.
                return $false;
            }
            else
            {
                if ($process.Path -ne $this.ModulePath)
                {
                    # Process is not the expected executable, the HERNIS FLEX Watchdog likely terminated improperly and process id has been reused by other process.
                    return $false;
                }
                else
                {
                    # Found process with correct path.
                    return $true;
                }
            }
        }
        
        return $false;
    }
}

class FlexWatchdog
{    
    [Collections.Generic.List[FlexModule]]GetModules()
    {
        $HernisWatchdogRegPath = "HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog"
        $modules = New-Object Collections.Generic.List[FlexModule]
        if ($this.Installed())
        {
            $moduleCount = Get-ItemPropertyValue -Path "$HernisWatchdogRegPath\Installed" -Name Count
            for ($moduleNo = 1; $moduleNo -le $moduleCount; $moduleNo++)
            {
                $newObject = New-Object FlexModule
                $null = $newObject.Initialize($moduleNo);
                $null = $modules.Add($newObject)
            }
        }
        return $modules
    }

    [bool]Installed()
    {
        $TaskName = "HERNIS Watchdog";
        $TaskInfo = Get-ScheduledTask -TaskName $TaskName;
        if ($null -ne $TaskInfo)
        {
            return $true;
        }
        return $false;
    }

    [bool]Running()
    {
        $TaskName = "HERNIS Watchdog";
        $TaskInfo = Get-ScheduledTask -TaskName $TaskName;
        if ($null -ne $TaskInfo)
        {
            if ($TaskInfo.State -eq "Running")
            { 
                return $true;
            }
        }
        return $false;
    }

    Start()
    {
        $TaskName = "HERNIS Watchdog";
        $TaskInfo = Get-ScheduledTask -TaskName $TaskName;
        if ($null -ne $TaskInfo)
        {
            if ($TaskInfo.State -ne "Running")
            { 
                Write-Host Starting $TaskName
                Start-ScheduledTask -TaskName $TaskName
            }
            else
            {
                Write-Host The $TaskName is already running.
            }
        }
        else
        {
            Write-Host The $TaskName is missing.
        }
    }

    Stop()
    {
        $TaskName = "HERNIS Watchdog";
        $TaskInfo = Get-ScheduledTask -TaskName $TaskName;
        if ($null -ne $TaskInfo)
        {
            if ($TaskInfo.State -ne "Running")
            { 
                Write-Host The $TaskName is not running.
                return;
            }
        }
        else
        {
            Write-Host The $TaskName is missing.
            return;
        }

        # Signal stop for all modules.
        $this.GetModules() | ForEach-Object { $_.Stop();}

        # Wait for all modules to stop.
        $bAllStopped = $false;
        while ($bAllStopped -eq $false)
        {        
            $bAllStopped = $true;
            foreach ($module in $this.GetModules())
            {
                if ($module -is [FlexModule])
                {
                    [FlexModule]$flexModule = $module
                    $isRunning  = $flexModule.IsRunning();
                    if ($isRunning)
                    {
                        # Still waiting for all modules to stop.
                        $bAllStopped = $false;
                    }
                }
            }
            if ($bAllStopped -eq $false)
            {
                Write-Host Waiting for all modules to stop.
                Start-Sleep -Milliseconds 250
            }
        }

        # Lastly stop the scheduled task.
        Write-Host Stopping $TaskName
        Stop-ScheduledTask -TaskName $TaskName
    }
}


# ------------------------------------------------------------------------------------------------------------------------
# Cmdlets
# ------------------------------------------------------------------------------------------------------------------------

<#
.INPUTS
You can pipe the output from the Get-FlexModuleList into Get-FlexModuleByName

.SYNOPSIS
Finds a module in the list of modules by name.

.EXAMPLE
Get-FlexModuleList | Format-Table  

.EXAMPLE
Get-FlexModuleList | Get-FlexModuleByName -ModuleName DataModule    

.EXAMPLE
Get-FlexModuleList | ForEach-Object { $_.Start()}    

.EXAMPLE
Get-FlexModuleList | ForEach-Object { $_.Stop()}    
#>
function Get-FlexModuleByName
{
    [OutputType([FlexModule])]
    param(
         [Parameter(Mandatory=$true, ValueFromPipeline)]
         [Collections.Generic.List[FlexModule]]$ModuleList,
 
         [Parameter(Mandatory=$true)]
         [string]$ModuleName
    )
    foreach ($module in $ModuleList)
    {
        if ($module -is [FlexModule])
        {
            [FlexModule]$flexModule = $module
            if ($flexModule.ModuleName -eq $ModuleName)
            {
                return , $flexModule
            }
        }
    }
    return $null
}

<#
.SYNOPSIS
    Gets a list of all modules configured in the HERNIS FLEX Watchdog
#>
function Get-FlexModuleList
{
    [CmdletBinding()]
    [OutputType([Collections.Generic.List[FlexModule]])]
    $HernisWatchdogRegPath = "HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog"
    $modules = New-Object Collections.Generic.List[FlexModule]
    $moduleCount = Get-ItemPropertyValue -Path "$HernisWatchdogRegPath\Installed" -Name Count
    for ($moduleNo = 1; $moduleNo -le $moduleCount; $moduleNo++)
    {
        $newObject = New-Object FlexModule
        $null = $newObject.Initialize($moduleNo);
        $null = $modules.Add($newObject)
    }
    return , $modules
}

<#
.SYNOPSIS
    Gets the HERNIS FLEX Watchdog object
#>
function Get-FlexWatchdog
{
    [CmdletBinding()]
    [OutputType([FlexWatchdog])]
    $watchdog = New-Object FlexWatchdog;
    return $watchdog;    
}


<#
.SYNOPSIS
Starts the HERNIS Watchdog.
The watchdog will automatically start all HERNIS FLEX modules.
#>
function Start-FlexWatchdog
{
    [CmdletBinding()]
    $watchdog = New-Object FlexWatchdog;
    if ($null -ne $watchdog)
    {
        $watchdog.Start();
    }
}

<#
.SYNOPSIS
    Stops all HERNIS FLEX modules and then stops the HERNIS Watchdog.
#>
function Stop-FlexWatchdog
{
    [CmdletBinding()]
    $watchdog = New-Object FlexWatchdog;
    if ($null -ne $watchdog)
    {
        $watchdog.Stop();
    }
}

<#
.SYNOPSIS
Starts the specified module in the HERNIS FLEX System.
#>
function Start-FlexModule
{
    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true)]
         [string]$ModuleName
    )

    $ModuleList = Get-FlexModuleList;
    $Module = Get-FlexModuleByName -ModuleList $ModuleList -ModuleName $ModuleName;
    if ($null -eq $Module)
    {
        Write-Warning "Module not found, start module aborted."
        return;
    }
    $Module.Start();
}

<#
.SYNOPSIS
Starts the specified module in the HERNIS FLEX System.
#>
function Set-FlexModuleStartup
{
    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true)]
         [string]$ModuleName,
         [Parameter(Mandatory=$true)]
         [bool]$AutomaticStartup
    )

    $ModuleList = Get-FlexModuleList;
    $Module = Get-FlexModuleByName -ModuleList $ModuleList -ModuleName $ModuleName;
    if ($null -eq $Module)
    {
        Write-Warning "Module not found, command aborted."
        return;
    }
    $Success = $Module.SetStartup($AutomaticStartup);
    if ($false -eq $Success)
    {
        Write-Warning "Unable to set startup mode."
        return;
    }
}

<#
.SYNOPSIS
Stops the specified module in the HERNIS FLEX System.
#>
function Stop-FlexModule
{
    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true)]
         [string]$ModuleName
    )

    $ModuleList = Get-FlexModuleList;
    $Module = Get-FlexModuleByName -ModuleList $ModuleList  -ModuleName $ModuleName;
    if ($null -eq $Module)
    {
        Write-Warning "Module not found, stop module aborted."
        return;
    }
    $Module.Stop();
}



<#
.SYNOPSIS
Checks if the HERNIS FLEX Watchdog is running.
.DESCRIPTION
Checks if the HERNIS FLEX Watchdog is running.
NOTE $true is returned even if the other modules are running.
.OUTPUTS
Returns $true if the "HERNIS FLEX Watchdog" Scheduled Task is running
#>
function Get-FlexWatchdogRunning
{
    [CmdletBinding()]
    $watchdog = New-Object FlexWatchdog;
    if ($null -ne $watchdog)
    {
        return $watchdog.Running();
    }
    return $false;
}

<#
.SYNOPSIS
Checks if the the Windows SNMP is responding.
.DESCRIPTION
Checks if the the Windows SNMP is responding by sending a SNMP message.
NOTE Use the Verbose flag to get verbose output.
.OUTPUTS
Returns $true if a response was received, in no response id received $false will be returned.
#>
function Test-WindowsSnmp
{
    param(
         [Parameter()]
         [string]$Community = "HernisSNMP",
         [Parameter(Mandatory=$true)]
         [string]$HostName
    )

    # Windows / Machine Information OID
    $winHWSWInfo = ".1.3.6.1.2.1.1.1.0"

    Write-Verbose "Checking if the Windows SNMP on $HostName is responding"

    try
    {
    $SnmpObject = New-Object -ComObject olePrn.OleSNMP
    $SnmpObject.Open("$HostName","$Community", 2, 1000)
    $reply = $SnmpObject.Get("$winHWSWInfo")
    $SnmpObject.Close()
    }
    catch
    {
        Write-Verbose "  Failed, no response received from the Windows SNMP service."
        Write-Verbose "  Check if the Windows SNMP service is running and that it allows the $Community community (Case-Sensitive)."
        return $false;
    }
    Write-Verbose "  Success, response received from the Windows SNMP service."
   return $true;
}

<#
.SYNOPSIS
Checks if the the LSI RAID SNMP Extension Agent is responding.
.DESCRIPTION
Checks if the the LSI RAID SNMP Extension Agent is responding by sending a SNMP message.
NOTE Use the Verbose flag to get verbose output.
.OUTPUTS
Returns $true if a response was received, in no response id received $false will be returned.
#>
function Test-LsiRaidSnmp
{
   param(
         [Parameter()]
         [string]$Community = "HernisSNMP",
         [Parameter(Mandatory=$true)]
         [string]$HostName
   )

   $snmpResponseOk = Test-WindowsSnmp -Community $Community -HostName $HostName
   if ($false -eq $snmpResponseOk)
   {
      return $false
   }

   #LSI OIDs:
   $lsiModel               = ".1.3.6.1.4.1.3582.4.1.4.1.3.1.12.0"    # Model of the adapter.

    Write-Verbose "Checking if the LSI RAID SNMP Extension Agent on $HostName is responding"

    try
    {
    $SnmpObject = New-Object -ComObject olePrn.OleSNMP
    $SnmpObject.Open("$HostName","$Community", 2, 1000)
    $reply = $SnmpObject.Get("$lsiModel")
    $SnmpObject.Close()
    }
    catch
    {
        Write-Verbose "  Failed, no response received from the LSI RAID SNMP Extension Agent."
        Write-Verbose "  Check if the that the LSI RAID SNMP Extension Agent is installed."
        return $false;
    }
    Write-Verbose "  Success, response received from the LSI RAID SNMP Extension Agent."
   return $true;
}

function Get-TimeInGC
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$Module,
        [Parameter(Mandatory=$false)]
        [int]$IntervallMilliseconds = 1000,
        [Parameter(Mandatory=$false)]
        [int]$Repeat = 5
    )

    if ($IntervallMilliseconds -lt 200)
    {
        $IntervallMilliseconds = 200
    }
    if ($IntervallMilliseconds -gt 5000)
    {
        $IntervallMilliseconds = 5000
    }
    
    $remainingCount = 1
    if ($Repeat -gt 1)
    {
        $remainingCount = $Repeat
    }

    $values = [System.Collections.ArrayList]@()
    while ($remainingCount -gt 0)
    {
        $var = Get-Counter -Counter "\.NET CLR Memory($Module)\% Time in GC" -MaxSamples 1
        $intVar = $var.CounterSamples[0].CookedValue
        $dummy = $values.Add($intVar)
        
        $total = 0
        foreach ($item in $values)
        {
          $total = $total + $item    
        }
        $total = $total / $values.Count
        $total = [math]::Round($total, 2)
    
        $totalRolingAvg = 0
        $startIndex = [Math]::Max($values.Count - 10, 0)
        $count = $values.Count - $startIndex
        if ($count -gt 0)
        {
            foreach ($item in $values.GetRange($startIndex, $count))
            {
              $totalRolingAvg = $totalRolingAvg + $item    
            }
            $totalRolingAvg = $totalRolingAvg / $count
        }
        $totalRolingAvg = [math]::Round($totalRolingAvg, 2)
    
        $currentValue = [math]::Round($intVar, 2)
        Write-Host Current $currentValue - Average $total - RollingAvg $totalRolingAvg
        
        $remainingCount--

        if ($remainingCount -gt 0)
        {
            Start-Sleep -Milliseconds $IntervallMilliseconds
        }
    }       
}

<#
.SYNOPSIS
Gets info from the LSI RAID SNMP Extension Agent.
.DESCRIPTION
Gets info from the LSI RAID SNMP Extension Agent.
#>
function Get-LsiRaidInfoFromSnmp
{
   param(
         [Parameter()]
         [string]$Community = "HernisSNMP",
         [Parameter(Mandatory=$true)]
         [string]$HostName
   )

   Write-Host "Getting LSI RAID info over SNMP:" -ForegroundColor Yellow

   $snmpResponseOk = Test-WindowsSnmp -Community $Community -HostName $HostName
   if ($false -eq $snmpResponseOk)
   {
      Write-Host "  Failed, no response received from the Windows SNMP service."
      Write-Host "    Check if the Windows SNMP service is running"
      Write-Host "    Check if the $Community community is allowed(Case-Sensitive)."
      Write-Host "    Check if SNMP is not blocked by a firewall."
      return;
   }

   #LSI OIDs:
   $lsiModel               = ".1.3.6.1.4.1.3582.4.1.4.1.3.1.12.0"    # Model of the adapter.
   $vdPresentCount         = ".1.3.6.1.4.1.3582.4.1.4.1.2.1.18.0"    # Virtual devices present in this adapter.
   $vdDegradedCount        = ".1.3.6.1.4.1.3582.4.1.4.1.2.1.19.0"
   $bbuState               = ".1.3.6.1.4.1.3582.4.1.4.1.6.2"
   $pdDiskPresentCount     = ".1.3.6.1.4.1.3582.4.1.4.1.2.1.22.0"
   $pdDiskFailedCount      = ".1.3.6.1.4.1.3582.4.1.4.1.2.1.24.0"
   $pdDiskPredFailureCount = ".1.3.6.1.4.1.3582.4.1.4.1.2.1.23.0"

   try
   {
      $SnmpObject = New-Object -ComObject olePrn.OleSNMP
      $SnmpObject.Open("$HostName","$Community", 2, 1000)

      Write-Host "  Model            : " -NoNewline ; $SnmpObject.Get("$lsiModel")
      Write-Host "  Virtual devices  : " -NoNewline ; $SnmpObject.Get("$vdPresentCount")
      Write-Host "  VD Degraded Cnt  : " -NoNewline ; $SnmpObject.Get("$vdDegradedCount")
      Write-Host "  PD Count         : " -NoNewline ; $SnmpObject.Get("$pdDiskPresentCount")
      Write-Host "  PD Failed Count  : " -NoNewline ; $SnmpObject.Get("$pdDiskFailedCount")
      Write-Host "  PD Pred. Fail Cnt: " -NoNewline ; $SnmpObject.Get("$pdDiskFailedCount")
      Write-Host "  BBU State        : " -NoNewline ; $SnmpObject.Get("$bbuState")

      $SnmpObject.Close()
    }
    catch
    {
        Write-Host "  Failed, no response received from the LSI RAID SNMP Extension Agent."
        Write-Host "    Check if the that the LSI RAID SNMP Extension Agent is installed."
    }
}


# ------------------------------------------------------------------------------------------------------------------------
# Exports 
# ------------------------------------------------------------------------------------------------------------------------

Export-ModuleMember -Function Stop-FlexWatchdog
Export-ModuleMember -Function Start-FlexWatchdog
Export-ModuleMember -Function Start-FlexModule
Export-ModuleMember -Function Stop-FlexModule
Export-ModuleMember -Function Get-FlexWatchdog
Export-ModuleMember -Function Get-FlexModuleByName
Export-ModuleMember -Function Get-FlexModuleList
Export-ModuleMember -Function Get-FlexWatchdogRunning
Export-ModuleMember -Function Set-FlexModuleStartup

Export-ModuleMember -Function Test-WindowsSnmp
Export-ModuleMember -Function Test-LsiRaidSnmp
Export-ModuleMember -Function Get-LsiRaidInfoFromSnmp

Export-ModuleMember -Function Get-TimeInGC
