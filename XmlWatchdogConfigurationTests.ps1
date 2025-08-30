<#
.SYNOPSIS
Unit tests for the XmlWatchdogConfiguration module.

.DESCRIPTION
This file contains unit tests for the XmlWatchdogConfiguration module using Pester v5.
The tests verify the functionality of loading and parsing the watchdog configuration XML file.

.NOTES
How to run the tests:
1. Ensure you have Pester v5 installed. If not, install it using:
   Install-Module -Name Pester -Force -SkipPublisherCheck

2. Set the PowerShell execution policy for the current session:
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

3. Import Pester v5 module:
   Import-Module Pester -RequiredVersion 5.7.1

4. Navigate to the FlexTools directory in PowerShell:
   cd C:\Repos\FlexTools

5. Run the tests using one of these commands:
   - Basic test run:
     Invoke-Pester -Path .\XmlWatchdogConfigurationTests.ps1
   - Detailed output:
     Invoke-Pester -Path .\XmlWatchdogConfigurationTests.ps1 -Output Detailed

   - Detailed output with verbose logging:
     $VerbosePreference = 'Continue'
     Invoke-Pester -Path .\XmlWatchdogConfigurationTests.ps1 -Output Detailed

   - To see test coverage:
     Invoke-Pester -Path .\XmlWatchdogConfigurationTests.ps1 -CodeCoverage .\XmlWatchdogConfiguration.psm1

Requirements:
- PowerShell 5.1 or later
- Pester v5 or later
- WatchdogConfiguration.xml file in the same directory
#>

using module "./XmlWatchdogConfiguration.psm1"

# Reset any existing instances
Remove-Variable -Name config -ErrorAction SilentlyContinue

Describe "XmlWatchdogConfiguration" {
    BeforeEach {
        $testXmlPath = Join-Path $PSScriptRoot "WatchdogConfiguration.xml"
        Write-Verbose "Using config file: $testXmlPath"
        $config = [XmlWatchdogConfiguration]::new($testXmlPath)
    }

    Context "Configuration Loading" {
        It "Should successfully load the configuration file" {
            $config.IsLoaded | Should -Be $true
        }

        It "Should validate the configuration" {
            $config.Validate() | Should -Be $true
        }
    }

    Context "Module Information" {
        It "Should return correct module count" {
            $config.GetModuleCount() | Should -Be 19
        }

        It "Should return all module names" {
            $moduleNames = $config.GetAllModuleNames()
            $moduleNames.Count | Should -Be 19
            $requiredModules = @(
                "ResourceModule",
                "CCTVModule",
                "DataModule",
                "HCVTModule",
                "ExternalSystemController",
                "AutomaticUpdateModule",
                "VMDModule",
                "DiagnosticModule",
                "MessageGateway",
                "RemoteModule",
                "HVRModule",
                "HVEModule",
                "MVEModule",
                "RESTModule",
                "LogicModule",
                "VisionAnalyticsIntegrationModule",
                "DeviceCommunicationModule",
                "WatchdogModule",
                "WatchdogReportModule"
            )
            
            foreach ($module in $requiredModules) {
                ($moduleNames -contains $module) | Should -BeTrue -Because "Module '$module' should be in the list"
            }
        }

        It "Should verify module presence" {
            $config.IsModulePresent("DataModule") | Should -BeTrue
            $config.IsModulePresent("NonExistentModule") | Should -BeFalse
        }

        It "Should return correct module path" {
            $dataModulePath = $config.GetModulePath("DataModule")
            $dataModulePath | Should -Be "C:\HERNIS\Modules\DataModule\DataModule.exe"
        }

        It "Should return empty string for non-existent module path" {
            $nonExistentPath = $config.GetModulePath("NonExistentModule")
            $nonExistentPath | Should -Be ""
        }
    }

    Context "Module Settings" {
        It "Should return all settings for DataModule" {
            $settings = $config.GetModuleSettings("DataModule")
            $settings["ModulePath"] | Should -Be "C:\HERNIS\Modules\DataModule\DataModule.exe"
            $settings["LocalDatabase"] | Should -Be "C:\HERNIS\Configuration\DataModule\HERNISSystemConfiguration.xml"
        }

        It "Should return all settings for HCVTModule" {
            # Get the settings and output them for debugging
            $settings = $config.GetModuleSettings("HCVTModule")
            Write-Host "HCVT Module settings: $(ConvertTo-Json $settings -Compress)"
            
            # Non-empty settings should be present with their values
            $settings["ModulePath"] | Should -Be "C:\HERNIS\Modules\HCVTModule\HCVTModule.exe"
            $settings["HttpPort"] | Should -Be "8443"
            $settings["UseHttps"] | Should -Be "True"
            
            # Empty settings should not be in the dictionary
            $settings.ContainsKey("Endpoint") | Should -BeFalse
        }

        It "Should return all settings for WatchdogModule" {
            $settings = $config.GetModuleSettings("WatchdogModule")
            $settings["ModulePath"] | Should -Be "C:\HERNIS\Modules\WatchdogModule\HernisWatchdogService.exe"
            $settings["WatchdogControlPort"] | Should -Be "4808"
        }

        It "Should return empty hashtable for non-existent module" {
            $settings = $config.GetModuleSettings("NonExistentModule")
            $settings.Count | Should -Be 0
        }
    }

    Context "Server Configuration" {
        It "Should return correct server port" {
            $config.GetServerPort() | Should -Be "4844"
        }

        It "Should return correct log folder" {
            $config.GetLogFolder() | Should -Be "C:\HERNIS\Logs"
        }

        It "Should return correct license value" {
            $config.GetLicenseValue() | Should -Be "hsscpc-1119-70773340"
        }
    }
}
