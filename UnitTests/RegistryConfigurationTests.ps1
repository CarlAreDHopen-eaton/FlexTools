using module "..\RegistryConfiguration.psm1"

# Reset any existing instances
Remove-Variable -Name regConfig -ErrorAction SilentlyContinue

Describe "RegistryConfiguration" {
    BeforeAll {
        # Mock registry paths for testing
        $mockWatchdogPath = "HKLM:\SOFTWARE\WOW6432Node\Hernis Scan Systems\WatchDog"
        $mockInstalledPath = "$mockWatchdogPath\Installed"
        $mockCommandPath = "$mockWatchdogPath\Command"
    }

    Context "Registry Key Management" {
        It "Should ensure key exists" {
            $result = [RegistryConfiguration]::EnsureKeyExists($mockWatchdogPath)
            $result | Should -BeTrue
            Test-Path $mockWatchdogPath | Should -BeTrue
        }
    }

    Context "Module Settings Management" {
        BeforeEach {
            # Setup test data in registry
            if (-not (Test-Path $mockInstalledPath)) {
                New-Item -Path $mockInstalledPath -Force
            }
            New-ItemProperty -Path $mockInstalledPath -Name "Count" -Value 1 -PropertyType DWORD -Force
            New-ItemProperty -Path $mockInstalledPath -Name "Path#1" -Value "C:\HERNIS\Modules\TestModule\TestModule.exe" -PropertyType STRING -Force
            New-ItemProperty -Path $mockInstalledPath -Name "Status#1" -Value 1 -PropertyType DWORD -Force
        }

        It "Should get module count" {
            $count = [RegistryConfiguration]::GetModuleCount()
            $count | Should -Be 1
        }

        It "Should get module string setting" {
            $path = [RegistryConfiguration]::GetModuleStringSetting(1, "Path", "")
            $path | Should -Be "C:\HERNIS\Modules\TestModule\TestModule.exe"
        }

        It "Should get module int setting" {
            $status = [RegistryConfiguration]::GetModuleIntSetting(1, "Status", 0)
            $status | Should -Be 1
        }

        It "Should set module int setting" {
            $result = [RegistryConfiguration]::SetModuleIntSetting(1, "Startup", 1)
            $result | Should -BeTrue
            
            # Verify the setting was saved
            $startup = [RegistryConfiguration]::GetModuleIntSetting(1, "Startup", 0)
            $startup | Should -Be 1
        }
    }

    Context "Module Command Operations" {
        It "Should set module command" {
            $result = [RegistryConfiguration]::SetModuleCommand(1, 1)
            $result | Should -BeTrue
        }
    }

    Context "Debug Settings Management" {
        It "Should set heap debugging" {
            $result = [RegistryConfiguration]::SetHeapDebugging("TestModule", "TestModule.exe", $true)
            $result | Should -BeTrue

            # Verify debug settings
            $debugPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\TestModule.exe"
            Test-Path $debugPath | Should -BeTrue
        }

        It "Should set crash dump settings" {
            $result = [RegistryConfiguration]::SetCrashDumpSettings("TestModule", "TestModule.exe", $true, 5)
            $result | Should -BeTrue

            # Verify dump settings
            $dumpPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\TestModule.exe"
            Test-Path $dumpPath | Should -BeTrue
        }
    }

    AfterAll {
        # Cleanup test registry entries
        $testPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\TestModule.exe",
            "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\TestModule.exe",
            $mockCommandPath,
            $mockInstalledPath,
            $mockWatchdogPath
        )

        foreach ($path in $testPaths) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force
            }
        }
    }
}
