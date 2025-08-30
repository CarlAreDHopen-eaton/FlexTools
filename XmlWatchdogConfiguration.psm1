class XmlWatchdogConfiguration
{
    [string] $ConfigPath
    [xml] $ConfigXml
    [bool] $IsLoaded = $false
    
    XmlWatchdogConfiguration([string]$configPath)
    {
        $this.ConfigPath = $configPath
        $this.LoadConfiguration()
    }

    XmlWatchdogConfiguration()
    {
        $this.ConfigPath = "C:\HERNIS\Configuration\WatchdogModule\WatchdogConfiguration.xml"
        $this.LoadConfiguration()
    }

    hidden [void] LoadConfiguration()
    {
        if (Test-Path -Path $this.ConfigPath) {
            try {
                [xml]$xml = Get-Content -Path $this.ConfigPath
                $this.ConfigXml = $xml
                $this.IsLoaded = $true
            }
            catch {
                Write-Warning "Failed to load watchdog configuration: $_"
                $this.IsLoaded = $false
            }
        }
        else {
            Write-Warning "Watchdog configuration file not found at: $($this.ConfigPath)"
            $this.IsLoaded = $false
        }
    }

    [bool] Validate()
    {
        if (-not $this.IsLoaded) {
            return $false
        }

        # Basic validation that essential elements exist
        if (-not $this.ConfigXml.HERNISFlexWatchdogConfiguration) {
            return $false
        }

        if (-not $this.ConfigXml.HERNISFlexWatchdogConfiguration.Modules) {
            return $false
        }

        return $true
    }

    [int] GetModuleCount()
    {
        if (-not $this.IsLoaded) {
            return 0
        }

        $count = 0
        foreach ($node in $this.ConfigXml.HERNISFlexWatchdogConfiguration.Modules.ChildNodes) {
            if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                $count++
            }
        }
        return $count
    }

    [string] GetModulePath([string]$moduleName)
    {
        $settings = $this.GetModuleSettings($moduleName)
        if ($settings.ContainsKey("ModulePath")) {
            return $settings["ModulePath"]
        }
        return ""
    }

    [hashtable] GetModuleSettings([string]$moduleName)
    {
        $settings = @{}
        
        if (-not $this.IsLoaded) {
            return $settings
        }

        # Find the module using XPath
        $moduleNode = $this.ConfigXml.SelectSingleNode("//HERNISFlexWatchdogConfiguration/Modules/$moduleName")
        if ($moduleNode) {
            # Process all child elements that have a non-empty Value attribute
            foreach ($element in $moduleNode.ChildNodes) {
                if ($element.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                    $valueAttr = $element.Attributes["Value"]
                    if ($null -ne $valueAttr -and $valueAttr.Value -ne "") {
                        $settings[$element.LocalName] = $valueAttr.Value
                    }
                }
            }
        }

        return $settings
    }

    [array] GetAllModuleNames()
    {
        $moduleNames = @()
        
        if (-not $this.IsLoaded) {
            return $moduleNames
        }

        foreach ($node in $this.ConfigXml.HERNISFlexWatchdogConfiguration.Modules.ChildNodes) {
            if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                $moduleNames += $node.LocalName
            }
        }

        return $moduleNames
    }

    [bool] IsModulePresent([string]$moduleName)
    {
        if (-not $this.IsLoaded) {
            return $false
        }

        return $null -ne $this.ConfigXml.SelectSingleNode("//HERNISFlexWatchdogConfiguration/Modules/$moduleName")
    }

    [string] GetServerPort()
    {
        if (-not $this.IsLoaded) {
            return ""
        }

        return $this.ConfigXml.HERNISFlexWatchdogConfiguration.Server.Port.Value
    }

    [string] GetLogFolder()
    {
        if (-not $this.IsLoaded) {
            return ""
        }

        return $this.ConfigXml.HERNISFlexWatchdogConfiguration.Log.Folder.Value
    }

    [string] GetLicenseValue()
    {
        if (-not $this.IsLoaded) {
            return ""
        }

        return $this.ConfigXml.HERNISFlexWatchdogConfiguration.Server.License.Value
    }
}

# Export the class
Export-ModuleMember -Function * -Variable *
