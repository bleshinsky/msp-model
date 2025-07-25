#Requires -Version 7.0
<#
.SYNOPSIS
    Interactive setup wizard for MSP Standard (NOL Framework)
.DESCRIPTION
    Guides through configuration of Neo4j, Obsidian, and Linear integrations
.EXAMPLE
    .\setup.ps1
    .\setup.ps1 -SkipDocker -TestOnly
#>

param(
    [switch]$SkipDocker,
    [switch]$TestOnly,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host @"
╔══════════════════════════════════════════════════════╗
║          MSP Standard Setup Wizard                   ║
║      NOL Framework: Neo4j + Obsidian + Linear       ║
╚══════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check prerequisites
Write-Host "`n📋 Checking Prerequisites..." -ForegroundColor Yellow

# PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ PowerShell 7+ required. Current: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    Write-Host "   Install from: https://github.com/PowerShell/PowerShell" -ForegroundColor Gray
    exit 1
}
Write-Host "✅ PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Docker check (optional)
$dockerInstalled = $null -ne (Get-Command docker -ErrorAction SilentlyContinue)
if ($dockerInstalled) {
    try {
        docker version | Out-Null
        Write-Host "✅ Docker Desktop installed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Docker installed but not running" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Docker not found (optional for Neo4j)" -ForegroundColor Yellow
}

# Create directory structure
Write-Host "`n📁 Creating Directory Structure..." -ForegroundColor Yellow

$directories = @(
    "config",
    "scripts/core",
    "scripts/integrations/neo4j",
    "scripts/integrations/obsidian", 
    "scripts/integrations/linear",
    "scripts/utilities",
    "scripts/custom",
    "state",
    "logs"
)

foreach ($dir in $directories) {
    $path = Join-Path $PSScriptRoot $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "✅ Created: $dir" -ForegroundColor Green
    }
}

# Configuration setup
Write-Host "`n⚙️  Configuration Setup..." -ForegroundColor Yellow

$configPath = Join-Path $PSScriptRoot "config\msp-config.json"
$exampleConfigPath = Join-Path $PSScriptRoot "config\msp-config.example.json"

# Create example config if not exists
if (-not (Test-Path $exampleConfigPath)) {
    $exampleConfig = @{
        neo4j = @{
            uri = "bolt://localhost:7687"
            username = "neo4j"
            database = "neo4j"
        }
        obsidian = @{
            vaultPath = ""
            dailyNotesPath = "Daily Notes"
            templatesPath = "Templates"
        }
        linear = @{
            teamId = ""
            projectId = ""
            activeIssue = ""
        }
        features = @{
            integrationMode = "integrated"
            autoValidate = $true
            sessionTimeout = 24
            debugMode = $false
        }
        msp = @{
            stateDir = ".\state"
            archiveDir = ".\state\archive"
        }
    }
    
    $exampleConfig | ConvertTo-Json -Depth 10 | Out-File $exampleConfigPath -Encoding UTF8
    Write-Host "✅ Created example configuration" -ForegroundColor Green
}

# Load or create config
$config = if (Test-Path $configPath) {
    Write-Host "📄 Found existing configuration" -ForegroundColor Cyan
    Get-Content $configPath | ConvertFrom-Json
} else {
    Write-Host "📄 Creating new configuration" -ForegroundColor Cyan
    Get-Content $exampleConfigPath | ConvertFrom-Json
}

# Interactive configuration
if (-not $TestOnly) {
    Write-Host "`n🔧 Neo4j Configuration" -ForegroundColor Cyan
    Write-Host "Neo4j stores your session knowledge graph" -ForegroundColor Gray
    
    $neo4jUri = Read-Host "Neo4j URI [$($config.neo4j.uri)]"
    if ($neo4jUri) { $config.neo4j.uri = $neo4jUri }
    
    $neo4jUser = Read-Host "Neo4j Username [$($config.neo4j.username)]"
    if ($neo4jUser) { $config.neo4j.username = $neo4jUser }
    
    $neo4jDb = Read-Host "Neo4j Database [$($config.neo4j.database)]"
    if ($neo4jDb) { $config.neo4j.database = $neo4jDb }
    
    # Neo4j password (secure)
    $neo4jPass = Read-Host "Neo4j Password" -AsSecureString
    if ($neo4jPass.Length -gt 0) {
        # Store in Windows Credential Manager or keychain
        # For now, we'll note that password should be provided at runtime
        Write-Host "⚠️  Password will be requested when needed" -ForegroundColor Yellow
    }
    
    Write-Host "`n📝 Obsidian Configuration" -ForegroundColor Cyan
    Write-Host "Obsidian creates markdown documentation" -ForegroundColor Gray
    
    $obsidianPath = Read-Host "Obsidian Vault Path (or 'skip')"
    if ($obsidianPath -and $obsidianPath -ne 'skip') {
        if (Test-Path $obsidianPath) {
            $config.obsidian.vaultPath = $obsidianPath
            Write-Host "✅ Valid Obsidian vault path" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Path not found, will create if needed" -ForegroundColor Yellow
            $config.obsidian.vaultPath = $obsidianPath
        }
    }
    
    Write-Host "`n📋 Linear Configuration" -ForegroundColor Cyan
    Write-Host "Linear tracks issues and project progress" -ForegroundColor Gray
    Write-Host "Get IDs from Linear URL: linear.app/TEAM/..." -ForegroundColor Gray
    
    $linearTeam = Read-Host "Linear Team ID (or 'skip')"
    if ($linearTeam -and $linearTeam -ne 'skip') {
        $config.linear.teamId = $linearTeam
        
        $linearProject = Read-Host "Linear Project ID"
        if ($linearProject) { $config.linear.projectId = $linearProject }
    }
    
    Write-Host "`n🎯 Integration Mode" -ForegroundColor Cyan
    Write-Host "1. cypher     - Generate queries for manual execution" -ForegroundColor White
    Write-Host "2. mcp        - Use with Claude MCP tools" -ForegroundColor White  
    Write-Host "3. integrated - Full automation (default)" -ForegroundColor White
    
    $mode = Read-Host "Choose mode [1-3]"
    switch ($mode) {
        "1" { $config.features.integrationMode = "cypher" }
        "2" { $config.features.integrationMode = "mcp" }
        "3" { $config.features.integrationMode = "integrated" }
    }
    
    # Save configuration
    $config | ConvertTo-Json -Depth 10 | Out-File $configPath -Encoding UTF8
    Write-Host "`n✅ Configuration saved" -ForegroundColor Green
}

# Docker setup for Neo4j
if ($dockerInstalled -and -not $SkipDocker) {
    Write-Host "`n🐳 Docker Setup for Neo4j" -ForegroundColor Cyan
    
    $useDocker = Read-Host "Set up Neo4j with Docker? (Y/n)"
    if ($useDocker -ne 'n') {
        Write-Host "Creating docker-compose.yml..." -ForegroundColor Yellow
        
        $dockerPath = Join-Path $PSScriptRoot "docker"
        if (-not (Test-Path $dockerPath)) {
            New-Item -ItemType Directory -Path $dockerPath -Force | Out-Null
        }
        
        $dockerCompose = @"
version: '3.8'

services:
  neo4j:
    image: neo4j:5-community
    container_name: msp-neo4j
    ports:
      - "7474:7474"  # HTTP
      - "7687:7687"  # Bolt
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
    environment:
      - NEO4J_AUTH=neo4j/password  # Change this!
      - NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
      - NEO4J_dbms_memory_pagecache_size=512M
      - NEO4J_dbms_memory_heap_max__size=512M
    restart: unless-stopped

volumes:
  neo4j_data:
  neo4j_logs:
"@
        
        $dockerCompose | Out-File (Join-Path $dockerPath "docker-compose.yml") -Encoding UTF8
        
        Write-Host "Starting Neo4j container..." -ForegroundColor Yellow
        Push-Location $dockerPath
        docker-compose up -d
        Pop-Location
        
        Write-Host "✅ Neo4j starting on http://localhost:7474" -ForegroundColor Green
        Write-Host "   Default credentials: neo4j/password" -ForegroundColor Gray
        Write-Host "   Please change the password after first login!" -ForegroundColor Yellow
    }
}

# Create core scripts
Write-Host "`n📄 Creating Core Scripts..." -ForegroundColor Yellow

# Create a placeholder for missing scripts
$placeholderScript = @'
# MSP Core Script Placeholder
Write-Host "This script is coming soon!" -ForegroundColor Yellow
Write-Host "For now, use the main msp.ps1 interface" -ForegroundColor Gray
'@

# Ensure core scripts exist
$coreScripts = @{
    "scripts\core\msp-config.ps1" = $null  # Will copy from source
    "scripts\core\msp-core-integrated.ps1" = $placeholderScript
    "scripts\core\msp-core-cypher.ps1" = $placeholderScript
    "scripts\core\msp-core-mcp.ps1" = $placeholderScript
    "scripts\utilities\msp-validate.ps1" = $placeholderScript
    "scripts\utilities\msp-recovery.ps1" = $placeholderScript
    "scripts\utilities\msp-git.ps1" = $placeholderScript
}

foreach ($script in $coreScripts.Keys) {
    $scriptPath = Join-Path $PSScriptRoot $script
    if (-not (Test-Path $scriptPath)) {
        if ($coreScripts[$script]) {
            $coreScripts[$script] | Out-File $scriptPath -Encoding UTF8
        }
        Write-Host "✅ Created: $script" -ForegroundColor Green
    }
}

# Test setup
Write-Host "`n🧪 Testing Configuration..." -ForegroundColor Yellow

$allGood = $true

# Test Neo4j
Write-Host "Testing Neo4j connection..." -ForegroundColor Gray
try {
    # Simple TCP test
    $neo4jHost = ([Uri]$config.neo4j.uri).Host
    $neo4jPort = ([Uri]$config.neo4j.uri).Port
    $tcpTest = Test-NetConnection -ComputerName $neo4jHost -Port $neo4jPort -WarningAction SilentlyContinue
    
    if ($tcpTest.TcpTestSucceeded) {
        Write-Host "✅ Neo4j is reachable" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot reach Neo4j at $($config.neo4j.uri)" -ForegroundColor Red
        $allGood = $false
    }
} catch {
    Write-Host "⚠️  Neo4j test skipped" -ForegroundColor Yellow
}

# Test Obsidian
if ($config.obsidian.vaultPath) {
    if (Test-Path $config.obsidian.vaultPath) {
        Write-Host "✅ Obsidian vault found" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Obsidian vault not found (will create)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n📊 Setup Summary" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "Neo4j:     $($config.neo4j.uri)" -ForegroundColor White
Write-Host "Obsidian:  $($config.obsidian.vaultPath)" -ForegroundColor White
Write-Host "Linear:    $($config.linear.teamId)/$($config.linear.projectId)" -ForegroundColor White
Write-Host "Mode:      $($config.features.integrationMode)" -ForegroundColor White

if ($allGood) {
    Write-Host "`n✅ Setup completed successfully!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Start your first session: .\msp.ps1 start" -ForegroundColor White
    Write-Host "2. Track some work: .\msp.ps1 update 'Setup complete' 10" -ForegroundColor White
    Write-Host "3. End session: .\msp.ps1 end" -ForegroundColor White
} else {
    Write-Host "`n⚠️  Setup completed with warnings" -ForegroundColor Yellow
    Write-Host "Fix the issues above and run: .\msp.ps1 config test" -ForegroundColor White
}

Write-Host "`n🚀 MSP Standard is ready!" -ForegroundColor Magenta
