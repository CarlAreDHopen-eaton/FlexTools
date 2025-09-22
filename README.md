# FLEX Tools
The FLEX tools powershell module contains various tools that can be used on HERNIS FLEX servers. 

*Features*
------------------------------------------------------------------------------------------------------
**Configuration Management:**
- Support for managing the HERNIS FLEX Registry configuration through the RegistryConfiguration module
- Support for XML-based watchdog configuration through the XmlWatchdogConfiguration module
- Includes comprehensive unit tests for both registry and XML configuration operations
- Functions for managing registry keys, module settings, and watchdog configuration in both formats

**Watchdog:**
- Support for starting the HERNIS FLEX Watchdog (**Start-FlexWatchdog**)
- Support for stopping the HERNIS FLEX Watchdog (**Stop-FlexWatchdog**)
- Support for getting the HERNIS FLEX Watchdog module list (**Get-FlexModuleList**)
- Support for getting single HERNIS FLEX Watchdog modules (**Get-FlexModuleByName**)
- Support for getting the HERNIS FLEX Watchdog (**Get-FlexWatchdog**)
- Support for checking if the HERNIS FLEX Watchdog is running (**Get-FlexWatchdogRunning**)
- Support for starting HERNIS FLEX Watchdog Modules (**Start-FlexModule**)
- Support for stopping HERNIS FLEX Watchdog Modules (**Stop-FlexModule**)
- Support for setting HERNIS FLEX Module startup (Automatic/Manual) (**Set-FlexModuleStartup**)

**Debugging:**
- Support for enabling debugging features (**Set-FlexModuleDebugMode**)

**SNMP:**
- Support for checking if the Windows SNMP service is responding (**Test-WindowsSnmp**)
- Support for checking if the LSI RAID SNMP extension agent is responding (**Test-LsiRaidSnmp**)
- Support for info from the LSI RAID SNMP extension agent (**Get-LsiRaidInfoFromSnmp**)

**Performance:**
- Support for checking the time spent in GC for FLEX modules (**Get-TimeInGC**)

*Installation of the PowerShell script on the HERNIS FLEX Server:*
-------------------------------------------------------------------------------------------------------

**Automated Installation (Recommended):**
1. Download or clone the FlexTools repository
2. Open PowerShell as Administrator 
3. Navigate to the FlexTools directory
4. Run: `.\Install-FlexTools.ps1`

The installation script will:
- Check for existing installations and compare versions
- Warn before downgrades and ask for confirmation
- Backup existing installations before upgrading
- Copy all required files to the system-wide PowerShell modules directory
  (C:\Windows\System32\WindowsPowerShell\v1.0\Modules for PowerShell 5.1)
- Provide post-installation instructions

**After Installation:**
Once installed, the FlexTools module is globally available in all PowerShell sessions. Simply:
1. Open a new PowerShell session
2. Run FlexTools commands directly (no `Import-Module` needed)
3. Example: `Get-FlexToolsVersion` or `Get-FlexWatchdog`

**Installation Options:**
- `.\Install-FlexTools.ps1` - Standard installation with version checking
- `.\Install-FlexTools.ps1 -Force` - Skip version checks and install anyway
- `.\Install-FlexTools.ps1 -WhatIf` - Show what would be installed without actually installing

**Manual Installation (Legacy):**
    - Open the following folder: C:\Windows\System32\WindowsPowerShell\v1.0\Modules
      (Note: This is the system-wide modules directory that requires Administrator privileges)
    - Make a folder named FlexTools
    - Copy the following files to the FlexTools folder:
      - FlexTools.psm1
      - RegistryConfiguration.psm1
      - XmlWatchdogConfiguration.psm1
    - For development and testing, also copy:
      - RegistryConfigurationTests.ps1 (and associated test data files)
      - XmlWatchdogConfigurationTests.ps1 (and associated XML test data)
    - Start a new PowerShell terminal window.
    - Use the exported functions.
    - In some cases you might have to run: Set-ExecutionPolicy -ExecutionPolicy Unrestricted

**Uninstallation:**
To remove FlexTools, run: `.\Uninstall-FlexTools.ps1`

**Version Checking:**
- Check current version: `Get-FlexToolsVersion`
- The installer automatically compares versions and prevents accidental downgrades

**Module Updates:**
To update an existing installation, simply run the installer again. It will automatically:
- Detect the current version and warn about downgrades
- Create a backup of the existing installation
- Install the new version

NOTE: No need to manually replace files - use the installer for all updates.

*Debugging module crashes in HERNIS FLEX:*
-------------------------------------------------------------------------------------------------------
Version 1.3 of the FLEX Tools script has support for enabling crash debugging features for FLEX modules using the **Set-FlexModuleDebugMode** function. The function has two parameters to enable debugging features in Windows, the **-CrashDump** and the **-HeapDebugging** parameters.

The **-CrashDump** parameter is used the enable/disable automatic generation of crash dumps when the specified module (specified by the **-ModuleName** parameter) crashes. The crash dumps are saved in c:\Dumps\\**ModuleName** and the script defaults too a maximum of 5 dumps per module (**-DumpCount**). 
 
The **-HeapDebugging** parameter toggles additional debugging flags in Windows. 
The flags are:
- Heap tail checking
- Heap free checking
- Heap parameter checking
- User mode stack trace database
- Heap tagging by DLL
- System critical breaks
- Page heap (full page heap)

Example:
![image](https://user-images.githubusercontent.com/14876765/207073076-12ed3d53-ebd5-4725-a332-6c3ce70bd80d.png)


**NOTE** The **-HeapDebugging** feature can have a performace and memory ussage impact on the module, only use this for debugging purposes and disable the feature after you have finished debugging the module.
