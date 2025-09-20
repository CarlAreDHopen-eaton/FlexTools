using module "..\RegistryConfiguration.psm1"

Describe "RegistryConfiguration" {
    BeforeEach {
        # Create instance
        $regConfig = [RegistryConfiguration]::new()

        # Import test registry data
        $regFilePath = Join-Path $PSScriptRoot "UnitTestRegistryData.reg"
        Write-Verbose "Importing test registry data from: $regFilePath"
        
        if (-not (Test-Path $regFilePath)) {
            throw "Registry file not found at: $regFilePath"
        }
        
        try {
            $result = reg import $regFilePath 2>&1
            Write-Verbose "Registry import result: $result"
        } 
        catch {
            Write-Warning "Failed to import registry data: $_"
        }

        # Setup test environment to use HKCU
        $regConfig.SetupForTesting()
        Write-Verbose "Set base path to: $($regConfig.WatchdogRegistryPath)"
    }

    Context "Registry Key Management" {
        It "Should ensure key exists" {
            $testPath = Join-Path ($regConfig.WatchdogRegistryPath) "TestKey"
            $result = $regConfig.EnsureKeyExists($testPath)
            $result | Should -BeTrue
            Test-Path $testPath | Should -BeTrue
        }
    }

    Context "Module Settings Management" {

        It "Should get module count" {
            $count = $regConfig.GetModuleCount()
            $count | Should -Be 13
        }

        It "Should get module string setting" {
            $path = $regConfig.GetModuleStringSetting(1, "Path", "")
            $path | Should -Be "c:\hernis\Modules\ResourceModule\ResourceModule.exe"
        }

        It "Should validate all module paths" {
            $expectedPaths = @(
                "c:\hernis\Modules\ResourceModule\ResourceModule.exe",
                "c:\HERNIS\Modules\CCTVModule\CCTVModule.exe",
                "c:\HERNIS\Modules\ExternalSystemController\ExternalSystemController.exe",
                "c:\HERNIS\Modules\AutomaticUpdateModule\AutomaticUpdateModule.exe",
                "c:\HERNIS\Modules\VMDModule\VMDModule.exe",
                "c:\HERNIS\Modules\RESTModule\RESTModule.exe",
                "c:\HERNIS\Modules\LogicModule\LogicModule.exe",
                "c:\HERNIS\Modules\VisionAnalyticsIntegrationModule\VisionAnalyticsIntegrationModule.exe",
                "c:\HERNIS\Modules\DeviceCommunicationModule\DeviceCommunicationModule.exe",
                "c:\HERNIS\Modules\DataModule\DataModule.exe",
                "c:\HERNIS\Modules\DiagnosticModule\DiagnosticModule.exe",
                "c:\HERNIS\Modules\MessageGateway\MessageGateway.exe",
                "c:\HERNIS\Modules\HVEModule\HVEModule.exe"
            )

            # Get the total count to verify we're testing all modules
            $count = $regConfig.GetModuleCount()
            $count | Should -Be $expectedPaths.Count

            # Check each module's path
            for ($i = 1; $i -le $count; $i++) {
                $path = $regConfig.GetModuleStringSetting($i, "Path", "")
                $path | Should -Be $expectedPaths[$i - 1]
            }
        }

        It "Should get module int setting" {
            $status = $regConfig.GetModuleIntSetting(1, "Status", 0)
            $status | Should -Be 1
        }

        It "Should set module int setting" {
            $result = $regConfig.SetModuleIntSetting(1, "Startup", 1)
            $result | Should -BeTrue
            
            # Verify the setting was saved
            $startup = $regConfig.GetModuleIntSetting(1, "Startup", 0)
            $startup | Should -Be 1
        }
    }

    Context "Module Command Operations" {
        It "Should set module command" {
            $result = $regConfig.SetModuleCommand(1, 1)
            $result | Should -BeTrue
        }
    }

    AfterEach {
        # Clean up any test keys created during individual tests
        if (Test-Path (Join-Path ($regConfig.WatchdogRegistryPath) "TestKey")) {
            Remove-Item -Path (Join-Path ($regConfig.WatchdogRegistryPath) "TestKey") -Force
        }
        
        # Clean up test registry keys
        if (Test-Path $regConfig.BaseRegistryPath) {
            Write-Verbose "Cleaning up test registry path: $($regConfig.BaseRegistryPath)"
            Remove-Item -Path ($regConfig.BaseRegistryPath) -Recurse -Force
        }
        # Reset paths back to production
        $regConfig.ResetToProductionPaths()
    }
}
