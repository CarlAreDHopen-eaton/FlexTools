# FLEX Tools
The FLEX tools powershell module contains various tools that can be used on HERNIS FLEX servers. 

*Features*
------------------------------------------------------------------------------------------------------
Watchdog:
- Support for starting the HERNIS FLEX Watchdog (**Start-FlexWatchdog**)
- Support for stopping the HERNIS FLEX Watchdog (**Stop-FlexWatchdog**)
- Support for getting the HERNIS FLEX Watchdog module list (**Get-FlexModuleList**)
- Support for getting single HERNIS FLEX Watchdog modules (**Get-FlexModuleByName**)
- Support for getting the HERNIS FLEX Watchdog (**Get-FlexWatchdog**)
- Support for checking if the HERNIS FLEX Watchdog is running (**Get-FlexWatchdogRunning**)
- Support for starting HERNIS FLEX Watchdog Modules (**Start-FlexModule**)
- Support for stopping HERNIS FLEX Watchdog Modules (**Stop-FlexModule**)
- Support for setting HERNIS FLEX Module startup (Automatic/Manual) (**Set-FlexModuleStartup**)

Debugging:
- Support for enabling debugging features (**Set-FlexModuleDebugMode**)
SNMP:
- Support for checking if the Windows SNMP service is responding (**Test-WindowsSnmp**)
- Support for checking if the LSI RAID SNMP extension agent is responding (**Test-LsiRaidSnmp**)
- Support for info from the LSI RAID SNMP extension agent (**Get-LsiRaidInfoFromSnmp**)

Performance:
- Support for checking the time spent in GC for FLEX modules (**Get-TimeInGC**)

*Installation of the PowerShell script on the HERNIS FLEX Server:*
-------------------------------------------------------------------------------------------------------
    - Open the following folder: C:\Windows\System32\WindowsPowerShell\v1.0\Modules
    - Make a folder named FlexTools
    - Copy FlexTools.psm1 to the FlexTools folder
    - Start a new PowerShell terminal window.
    - Use the exported functions.


*Debugging module crashes HERNIS FLEX Server:*
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

**NOTE** The **-HeapDebugging** feature can have a performace and memory ussage impact on the module, only use this for debugging purposes and disable the feature after you have finished debugging the module.
