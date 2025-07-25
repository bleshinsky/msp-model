<#
.SYNOPSIS
    MSP Standard - Full NOL Framework implementation
.DESCRIPTION
    Mandatory Session Protocol with Neo4j, Obsidian, and Linear integration.
    Implements the R³ (Route-Recall-Record) protocol for context engineering.
.NOTES
    Version: 2.0.0
    Framework: NOL (Neo4j + Obsidian + Linear)
#>

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Param1,
    
    [Parameter(Position=2)]
    [string]$Param2
)

$ProjectRoot = $PSScriptRoot
Set-Location $ProjectRoot

# Initialize MSP environment
if (-not (Test-Path "$ProjectRoot\scripts\core\msp-config.ps1")) {
    Write-Host "❌ MSP scripts not found. Run setup.ps1 first!" -ForegroundColor Red
    exit 1
}

# Load configuration
. "$ProjectRoot\scripts\core\msp-config.ps1"
$config = Get-MSPConfig

# Validate environment
if (-not $config) {
    Write-Host "❌ Failed to load configuration. Run setup.ps1 to configure MSP." -ForegroundColor Red
    exit 1
}

# Get integration mode
$integrationMode = $config.features.integrationMode

# Select core script based on mode
$coreScript = switch ($integrationMode) {
    "cypher" { "msp-core-cypher.ps1" }
    "mcp" { "msp-core-mcp.ps1" }
    "integrated" { "msp-core-integrated.ps1" }
    default { "msp-core-integrated.ps1" }
}

# Command processing
switch ($Command) {
    "start" {
        Write-Host "🚀 Starting MSP session..." -ForegroundColor Cyan
        Write-Host "Mode: $integrationMode" -ForegroundColor Gray
        & "$ProjectRoot\scripts\core\$coreScript" -Action start
    }
    
    "update" {
        if (-not $Param1) {
            Write-Host "Usage: .\msp.ps1 update 'description' [progress]" -ForegroundColor Red
            Write-Host "Example: .\msp.ps1 update 'Implemented user auth' 25" -ForegroundColor Gray
            return
        }
        $progress = if ($Param2) { [int]$Param2 } else { -1 }
        & "$ProjectRoot\scripts\core\$coreScript" -Action update -Notes $Param1 -Progress $progress
    }
    
    "end" {
        Write-Host "📊 Ending MSP session..." -ForegroundColor Cyan
        & "$ProjectRoot\scripts\core\$coreScript" -Action end
    }
    
    "status" {
        & "$ProjectRoot\scripts\core\$coreScript" -Action status
    }
    
    "recall" {
        Write-Host "🧠 Recalling context..." -ForegroundColor Cyan
        & "$ProjectRoot\scripts\core\$coreScript" -Action recall
    }
    
    "route" {
        if (-not $Param1) {
            Write-Host "Usage: .\msp.ps1 route 'goal description'" -ForegroundColor Red
            return
        }
        & "$ProjectRoot\scripts\core\$coreScript" -Action route -Goal $Param1
    }
    
    "context" {
        $format = if ($Param1) { $Param1 } else { "ai" }
        & "$ProjectRoot\scripts\core\$coreScript" -Action context -Format $format
    }
    
    "validate" {
        & "$ProjectRoot\scripts\utilities\msp-validate.ps1"
    }
    
    "recover" {
        & "$ProjectRoot\scripts\utilities\msp-recovery.ps1" @args
    }
    
    "sessions" {
        & "$ProjectRoot\scripts\utilities\msp-recovery.ps1" -List
    }
    
    "config" {
        if ($Param1 -eq "show") {
            Show-MSPConfig
        } elseif ($Param1 -eq "edit") {
            $configPath = "$ProjectRoot\config\msp-config.json"
            if ($env:EDITOR) {
                & $env:EDITOR $configPath
            } else {
                notepad $configPath
            }
        } elseif ($Param1 -eq "test") {
            Test-MSPConfiguration
        } elseif ($Param1 -and $Param2) {
            Set-MSPConfig -Path $Param1 -Value $Param2
        } else {
            Write-Host "Configuration Commands:" -ForegroundColor Yellow
            Write-Host "  .\msp.ps1 config show           Show current config" -ForegroundColor White
            Write-Host "  .\msp.ps1 config edit           Open config in editor" -ForegroundColor White
            Write-Host "  .\msp.ps1 config test           Test all integrations" -ForegroundColor White
            Write-Host "  .\msp.ps1 config <key> <value>  Set config value" -ForegroundColor White
            Write-Host ""
            Write-Host "Example:" -ForegroundColor Gray
            Write-Host "  .\msp.ps1 config linear.activeIssue NOA-234" -ForegroundColor Gray
        }
    }
    
    "neo4j" {
        Write-Host "🔗 Neo4j Integration" -ForegroundColor Cyan
        Write-Host ""
        if ($Param1 -eq "test") {
            & "$ProjectRoot\scripts\integrations\neo4j\test-connection.ps1"
        } elseif ($Param1 -eq "setup") {
            & "$ProjectRoot\scripts\integrations\neo4j\setup-neo4j.ps1"
        } else {
            Write-Host "Neo4j Commands:" -ForegroundColor Yellow
            Write-Host "  .\msp.ps1 neo4j test    Test Neo4j connection" -ForegroundColor White
            Write-Host "  .\msp.ps1 neo4j setup   Run Neo4j setup wizard" -ForegroundColor White
            Write-Host ""
            Write-Host "Current Status:" -ForegroundColor Yellow
            $neo4jConfig = $config.neo4j
            Write-Host "  URI: $($neo4jConfig.uri)" -ForegroundColor Gray
            Write-Host "  Database: $($neo4jConfig.database)" -ForegroundColor Gray
        }
    }
    
    "obsidian" {
        Write-Host "📝 Obsidian Integration" -ForegroundColor Cyan
        if ($Param1 -eq "open") {
            & "$ProjectRoot\scripts\integrations\obsidian\open-vault.ps1"
        } else {
            Write-Host "Vault: $($config.obsidian.vaultPath)" -ForegroundColor Gray
        }
    }
    
    "linear" {
        Write-Host "📋 Linear Integration" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Ask Claude to:" -ForegroundColor Yellow
        Write-Host "1. List issues in project: $($config.linear.projectId)" -ForegroundColor White
        Write-Host "2. Update issue: $($config.linear.activeIssue)" -ForegroundColor White
        Write-Host "3. Add session comments" -ForegroundColor White
    }
    
    "git" {
        & "$ProjectRoot\scripts\utilities\msp-git.ps1" @args
    }
    
    "mode" {
        Write-Host "Integration Mode: $integrationMode" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Available modes:" -ForegroundColor Yellow
        Write-Host "  cypher     - Generate Cypher queries for manual execution" -ForegroundColor White
        Write-Host "  mcp        - Use MCP tools (Claude integration)" -ForegroundColor White
        Write-Host "  integrated - Full automatic integration" -ForegroundColor White
        Write-Host ""
        Write-Host "Change with: .\msp.ps1 config features.integrationMode <mode>" -ForegroundColor Gray
    }
    
    "help" {
        Write-Host @"

MSP Standard - Mandatory Session Protocol (NOL Framework)
=========================================================

The R³ Protocol: Route → Recall → Record
        
CORE COMMANDS:
  start                 Begin new session (RECALL previous context)
  update 'msg' [%]     Track progress (RECORD achievements)  
  end                  Complete session (RECORD final state)
  
CONTEXT COMMANDS:
  status               Show current session
  recall               Load previous context
  route 'goal'         Set session destination
  context [format]     Export full context (ai/json/md)
  
INTEGRATION COMMANDS:
  neo4j [test|setup]   Neo4j graph database
  obsidian [open]      Obsidian vault access
  linear               Linear project info
  
UTILITY COMMANDS:
  config [cmd]         Configuration management
  validate             Check system health
  recover              Recover crashed session
  sessions             List session history
  git [commit]         Generate commit message
  mode                 Show integration mode
  help                 Show this help
  
EXAMPLES:
  .\msp.ps1 start
  .\msp.ps1 route "Implement authentication system"
  .\msp.ps1 update "Created user model" 10
  .\msp.ps1 update "Added JWT middleware" 25
  .\msp.ps1 end
  
  .\msp.ps1 context | clip     # Copy context for AI
  .\msp.ps1 config show         # View configuration
  .\msp.ps1 neo4j test          # Test Neo4j connection
  
LEARN MORE:
  Docs: https://docs.sessionprotocol.dev
  R³ Protocol: https://sessionprotocol.dev/r3

"@ -ForegroundColor Cyan
    }
    
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Run '.\msp.ps1 help' for usage" -ForegroundColor Yellow
    }
}
