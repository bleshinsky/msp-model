<#
.SYNOPSIS
    Central configuration management for MSP Standard
.DESCRIPTION
    Handles config loading, validation, defaults, and environment variables
#>

# Default configuration
$script:DefaultConfig = @{
    obsidian = @{
        vaultPath = ""
        templatesPath = "Templates"
        dailyNotesPath = "Daily Notes"
        decisionsPath = "Decisions"
    }
    
    linear = @{
        teamId = ""
        projectId = ""
        epicIds = @{}
        labels = @{
            session = "msp-session"
            decision = "msp-decision"
            blocker = "msp-blocker"
        }
    }
    
    neo4j = @{
        database = "neo4j"
        boltUri = "bolt://localhost:7687"
    }
    
    msp = @{
        stateDir = ".msp"
        archiveDir = ".msp\archive"
        sessionTimeout = 24  # hours
        autoValidate = $true
        debugMode = $false
    }
}

function Get-MSPConfig {
    <#
    .SYNOPSIS
        Gets the MSP configuration with environment overrides
    .DESCRIPTION
        Loads config from file, applies environment variables, validates
    #>
    param(
        [switch]$Force  # Force reload from disk
    )
    
    # Return cached config if available
    if ($script:CurrentConfig -and -not $Force) {
        return $script:CurrentConfig
    }
    
    # Start with defaults
    $config = $script:DefaultConfig | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    
    # Load user config if exists
    $configPath = "config\msp-config.json"
    if (Test-Path $configPath) {
        try {
            $userConfig = Get-Content $configPath | ConvertFrom-Json
            $config = Merge-Config -Base $config -Override $userConfig
        } catch {
            Write-Warning "Failed to load user config: $_"
        }
    }
    
    # Apply environment variable overrides
    $config = Apply-EnvironmentOverrides -Config $config
    
    # Validate configuration
    $validation = Test-ConfigValidity -Config $config
    if (-not $validation.Valid) {
        Write-Warning "Configuration issues found:"
        $validation.Issues | ForEach-Object { Write-Warning "  - $_" }
    }
    
    # Cache and return
    $script:CurrentConfig = $config
    return $config
}

function Set-MSPConfig {
    <#
    .SYNOPSIS
        Updates MSP configuration
    .EXAMPLE
        Set-MSPConfig -Path "linear.teamId" -Value "abc-123"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        $Value
    )
    
    $config = Get-MSPConfig -Force
    
    # Navigate to the property
    $parts = $Path -split '\.'
    $current = $config
    
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        if (-not $current.PSObject.Properties[$parts[$i]]) {
            $current | Add-Member -MemberType NoteProperty -Name $parts[$i] -Value @{} -Force
        }
        $current = $current.$($parts[$i])
    }
    
    # Set the value
    $lastPart = $parts[-1]
    $current | Add-Member -MemberType NoteProperty -Name $lastPart -Value $Value -Force
    
    # Save to file
    Save-ConfigToFile -Config $config
    
    # Clear cache
    $script:CurrentConfig = $null
    
    Write-Host "✅ Updated config: $Path = $Value" -ForegroundColor Green
}

function Save-ConfigToFile {
    param($Config)
    
    $configPath = "config\msp-config.json"
    $configDir = Split-Path $configPath -Parent
    
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    $saveConfig = $Config | ConvertTo-Json -Depth 10 | Out-File $configPath -Encoding UTF8
}

function Merge-Config {
    param($Base, $Override)
    
    $result = $Base | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    
    foreach ($prop in $Override.PSObject.Properties) {
        if ($result.PSObject.Properties[$prop.Name] -and 
            $prop.Value -is [PSCustomObject] -and 
            $result.$($prop.Name) -is [PSCustomObject]) {
            # Recursive merge for nested objects
            $result.$($prop.Name) = Merge-Config -Base $result.$($prop.Name) -Override $prop.Value
        } else {
            # Direct assignment
            $result | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
        }
    }
    
    return $result
}

function Apply-EnvironmentOverrides {
    param($Config)
    
    # Map of environment variables to config paths
    $envMappings = @{
        'MSP_OBSIDIAN_VAULT' = 'obsidian.vaultPath'
        'MSP_LINEAR_TEAM' = 'linear.teamId'
        'MSP_LINEAR_PROJECT' = 'linear.projectId'
        'MSP_NEO4J_URI' = 'neo4j.boltUri'
        'MSP_NEO4J_DATABASE' = 'neo4j.database'
        'MSP_STATE_DIR' = 'msp.stateDir'
        'MSP_DEBUG' = 'msp.debugMode'
    }
    
    # Also support legacy environment variables
    if ($env:OBSIDIAN_VAULT_PATH) { $env:MSP_OBSIDIAN_VAULT = $env:OBSIDIAN_VAULT_PATH }
    if ($env:LINEAR_TEAM_ID) { $env:MSP_LINEAR_TEAM = $env:LINEAR_TEAM_ID }
    if ($env:LINEAR_PROJECT_ID) { $env:MSP_LINEAR_PROJECT = $env:LINEAR_PROJECT_ID }
    
    foreach ($envVar in $envMappings.Keys) {
        if (Test-Path "env:$envVar") {
            $value = (Get-Item "env:$envVar").Value
            $path = $envMappings[$envVar]
            
            # Convert boolean strings
            if ($value -eq 'true') { $value = $true }
            elseif ($value -eq 'false') { $value = $false }
            
            # Apply the override
            $parts = $path -split '\.'
            $current = $Config
            
            for ($i = 0; $i -lt $parts.Count - 1; $i++) {
                $current = $current.$($parts[$i])
            }
            
            $current.$($parts[-1]) = $value
            
            if ($Config.msp.debugMode) {
                Write-Host "Config override: $envVar -> $path = $value" -ForegroundColor Gray
            }
        }
    }
    
    return $Config
}

function Test-ConfigValidity {
    param($Config)
    
    $issues = @()
    
    # Check required paths exist
    if ($Config.obsidian.vaultPath -and -not (Test-Path $Config.obsidian.vaultPath)) {
        $issues += "Obsidian vault path not found: $($Config.obsidian.vaultPath)"
    }
    
    # Check Linear IDs format
    if ($Config.linear.teamId -and $Config.linear.teamId -notmatch '^[a-f0-9-]{36}$') {
        $issues += "Linear team ID appears invalid (should be UUID format)"
    }
    
    if ($Config.linear.projectId -and $Config.linear.projectId -notmatch '^[a-f0-9-]{36}$') {
        $issues += "Linear project ID appears invalid (should be UUID format)"
    }
    
    # Check state directory is writable
    try {
        $testFile = Join-Path $Config.msp.stateDir "msp-test-$(Get-Random).tmp"
        "test" | Out-File $testFile -ErrorAction Stop
        Remove-Item $testFile -Force
    } catch {
        $issues += "State directory not writable: $($Config.msp.stateDir)"
    }
    
    return @{
        Valid = $issues.Count -eq 0
        Issues = $issues
    }
}

function Show-MSPConfig {
    <#
    .SYNOPSIS
        Displays current configuration
    #>
    param(
        [string]$Section  # Optional section to display
    )
    
    $config = Get-MSPConfig
    
    Write-Host "`n🔧 MSP Configuration" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    
    if ($Section) {
        if ($config.PSObject.Properties[$Section]) {
            Write-Host "`n[$Section]" -ForegroundColor Yellow
            $config.$Section | Format-List
        } else {
            Write-Host "Section not found: $Section" -ForegroundColor Red
        }
    } else {
        # Show all sections
        foreach ($prop in $config.PSObject.Properties) {
            Write-Host "`n[$($prop.Name)]" -ForegroundColor Yellow
            $prop.Value | Format-List
        }
    }
    
    Write-Host "`n💡 To update: Set-MSPConfig -Path 'section.property' -Value 'newvalue'" -ForegroundColor Gray
}

function Initialize-MSPConfig {
    <#
    .SYNOPSIS
        Interactive configuration setup
    #>
    Write-Host "🚀 MSP Configuration Setup" -ForegroundColor Magenta
    
    $config = Get-MSPConfig -Force
    
    # Obsidian
    Write-Host "`n📁 Obsidian Configuration" -ForegroundColor Cyan
    $vaultPath = Read-Host "Vault path [$($config.obsidian.vaultPath)]"
    if ($vaultPath) { Set-MSPConfig -Path "obsidian.vaultPath" -Value $vaultPath }
    
    # Linear
    Write-Host "`n📋 Linear Configuration" -ForegroundColor Cyan
    $teamId = Read-Host "Team ID [$($config.linear.teamId)]"
    if ($teamId) { Set-MSPConfig -Path "linear.teamId" -Value $teamId }
    
    $projectId = Read-Host "Project ID [$($config.linear.projectId)]"
    if ($projectId) { Set-MSPConfig -Path "linear.projectId" -Value $projectId }
    
    # Neo4j
    Write-Host "`n🔗 Neo4j Configuration" -ForegroundColor Cyan
    $neo4jUri = Read-Host "Neo4j URI [$($config.neo4j.boltUri)]"
    if ($neo4jUri) { Set-MSPConfig -Path "neo4j.boltUri" -Value $neo4jUri }
    
    Write-Host "`n✅ Configuration saved!" -ForegroundColor Green
    Show-MSPConfig
}

# Export functions (works when dot-sourced)
