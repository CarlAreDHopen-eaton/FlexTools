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
SNMP:
- Support for checking if the Windows SNMP service is responding (**Test-WindowsSnmp**)
- Support for checking if the LSI RAID SNMP extension agent is responding (**Test-LsiRaidSnmp**)
- Support for info from the LSI RAID SNMP extension agent (**Get-LsiRaidInfoFromSnmp**)
Performance:


*Installation of the PowerShell script on the HERNIS FLEX Server:*
-------------------------------------------------------------------------------------------------------
    - Open the following folder: C:\Windows\System32\WindowsPowerShell\v1.0\Modules
    - Make a folder named FlexTools
    - Copy FlexTools.psm1 to the FlexTools folder
    - Start a new PowerShell terminal window.
    - Use the exported functions.
