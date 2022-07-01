Import-Module .\FlexTools.psm1 -Force

#Get-FlexWatchdogRunning

#Get-FlexModuleList | Format-Table -AutoSize

#Get-FlexModuleList | Get-FlexModuleByName -ModuleName DataModule | Select-Object { $_.Start()}

Start-FlexModule -ModuleName DataModule