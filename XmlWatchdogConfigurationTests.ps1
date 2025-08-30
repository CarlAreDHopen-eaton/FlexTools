using module .\FlexTools.psm1

Describe "XmlWatchdogConfiguration" {
    $testXmlPath = Join-Path $PSScriptRoot "WatchdogConfiguration.xml"
    $config = $null

    BeforeEach {
        $config = [XmlWatchdogConfiguration]::new($testXmlPath)
    }
    $config = $null

    BeforeEach {
        $config = New-Object XmlWatchdogConfiguration($testXmlPath)
    }

    Context "Configuration Loading" {
        It "Should successfully load the configuration file" {
            $config.IsLoaded | Should Be $true
        }

        It "Should validate the configuration" {
            $config.Validate() | Should Be $true
        }
    }

    Context "Module Information" {
        It "Should return correct module count" {
            $config.GetModuleCount() | Should Be 19
        }

        It "Should return all module names" {
            $moduleNames = $config.GetAllModuleNames()
            $moduleNames.Count | Should Be 19
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
                ($moduleNames -contains $module) | Should Be $true -Because "Module '$module' should be in the list"
            }
        }

        It "Should verify module presence" {
            $config.IsModulePresent("DataModule") | Should Be $true
            $config.IsModulePresent("NonExistentModule") | Should Be $false
        }

        It "Should return correct module path" {
            $dataModulePath = $config.GetModulePath("DataModule")
            $dataModulePath | Should Be "C:\HERNIS\Modules\DataModule\DataModule.exe"
        }

        It "Should return empty string for non-existent module path" {
            $nonExistentPath = $config.GetModulePath("NonExistentModule")
            $nonExistentPath | Should Be ""
        }
    }

    Context "Module Settings" {
        It "Should return all settings for DataModule" {
            $settings = $config.GetModuleSettings("DataModule")
            $settings["ModulePath"] | Should Be "C:\HERNIS\Modules\DataModule\DataModule.exe"
            $settings["LocalDatabase"] | Should Be "C:\HERNIS\Configuration\DataModule\HERNISSystemConfiguration.xml"
        }

        It "Should return all settings for HCVTModule" {
            # Get the settings and output them for debugging
            $settings = $config.GetModuleSettings("HCVTModule")
            Write-Host "HCVT Module settings: $(ConvertTo-Json $settings -Compress)"
            
            # Non-empty settings should be present with their values
            $settings["ModulePath"] | Should Be "C:\HERNIS\Modules\HCVTModule\HCVTModule.exe"
            $settings["HttpPort"] | Should Be "8443"
            $settings["UseHttps"] | Should Be "True"
            
            # Empty settings should not be in the dictionary
            $settings.ContainsKey("Endpoint") | Should Be $false
        }

        It "Should return all settings for WatchdogModule" {
            $settings = $config.GetModuleSettings("WatchdogModule")
            $settings["ModulePath"] | Should Be "C:\HERNIS\Modules\WatchdogModule\HernisWatchdogService.exe"
            $settings["WatchdogControlPort"] | Should Be "4808"
        }

        It "Should return empty hashtable for non-existent module" {
            $settings = $config.GetModuleSettings("NonExistentModule")
            $settings.Count | Should Be 0
        }
    }

    Context "Server Configuration" {
        It "Should return correct server port" {
            $config.GetServerPort() | Should Be "4844"
        }

        It "Should return correct log folder" {
            $config.GetLogFolder() | Should Be "C:\HERNIS\Logs"
        }

        It "Should return correct license value" {
            $config.GetLicenseValue() | Should Be "hsscpc-1119-70773340"
        }
    }
}
