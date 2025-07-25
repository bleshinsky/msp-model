<#
.SYNOPSIS
    MSP validation and health checks
.DESCRIPTION
    Validates system state, checks for issues, and provides recovery guidance
#>

# Load dependencies
. "$PSScriptRoot\msp-config.ps1"
. "$PSScriptRoot\msp-error-handler.ps1"

function Test-MSPHealth {
    <#
    .SYNOPSIS
        Comprehensive health check for MSP
    .DESCRIPTION
        Checks all components and returns detailed status
    #>
    
    Write-Host "`n🔍 MSP Health Check" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    $issues = @()
    $warnings = @()
    
    # Check PowerShell version
    Write-Host "`nChecking PowerShell..." -NoNewline
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ❌" -ForegroundColor Red
        $issues += "PowerShell 7+ required (current: $($PSVersionTable.PSVersion))"
    }
    
    # Check MSP directories
    Write-Host "Checking directories..." -NoNewline
    $requiredDirs = @(".msp", ".msp\archive", ".msp\errors")
    $dirIssues = 0
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            try {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            } catch {
                $dirIssues++
                $issues += "Cannot create directory: $dir"
            }
        }
    }
    if ($dirIssues -eq 0) {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ❌" -ForegroundColor Red
    }
    
    # Check current session
    Write-Host "Checking session state..." -NoNewline
    $sessionFile = ".msp\current-session.json"
    if (Test-Path $sessionFile) {
        try {
            $session = Get-Content $sessionFile | ConvertFrom-Json
            if ($session.status -eq 'active') {
                $duration = [Math]::Round((Get-Date - [DateTime]::Parse($session.startTime)).TotalHours, 2)
                if ($duration -gt 8) {
                    Write-Host " ⚠️" -ForegroundColor Yellow
                    $warnings += "Session has been active for $duration hours"
                } else {
                    Write-Host " ✅" -ForegroundColor Green
                }
            } else {
                Write-Host " ⚠️" -ForegroundColor Yellow
                $warnings += "Inactive session found in state file"
            }
        } catch {
            Write-Host " ❌" -ForegroundColor Red
            $issues += "Corrupted session file"
        }
    } else {
        Write-Host " ✅" -ForegroundColor Green
    }
    
    # Check configuration
    Write-Host "Checking configuration..." -NoNewline
    try {
        $config = Get-MSPConfig
        $validation = Test-ConfigValidity -Config $config
        if ($validation.Valid) {
            Write-Host " ✅" -ForegroundColor Green
        } else {
            Write-Host " ⚠️" -ForegroundColor Yellow
            $warnings += $validation.Issues
        }
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        $issues += "Cannot load configuration"
    }
    
    # Check integrations
    Write-Host "Checking integrations..." -NoNewline
    $integrationIssues = 0
    
    # Neo4j
    if ($config.neo4j.boltUri) {
        # Just check if URI is valid format
        if ($config.neo4j.boltUri -notmatch '^bolt://') {
            $integrationIssues++
            $warnings += "Neo4j URI should start with bolt://"
        }
    }
    
    # Obsidian
    if ($config.obsidian.vaultPath) {
        if (-not (Test-Path $config.obsidian.vaultPath)) {
            $integrationIssues++
            $warnings += "Obsidian vault not found: $($config.obsidian.vaultPath)"
        }
    }
    
    # Linear
    if ($config.linear.teamId -and $config.linear.teamId -notmatch '^[a-f0-9-]{36}$') {
        $integrationIssues++
        $warnings += "Linear team ID format appears invalid"
    }
    
    if ($integrationIssues -eq 0) {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ⚠️" -ForegroundColor Yellow
    }
    
    # Check archive
    Write-Host "Checking archive..." -NoNewline
    $archiveDir = ".msp\archive"
    if (Test-Path $archiveDir) {
        $archiveFiles = Get-ChildItem $archiveDir -Filter "*.json" -ErrorAction SilentlyContinue
        $corruptedFiles = 0
        foreach ($file in $archiveFiles) {
            try {
                $null = Get-Content $file.FullName | ConvertFrom-Json
            } catch {
                $corruptedFiles++
            }
        }
        if ($corruptedFiles -eq 0) {
            Write-Host " ✅ ($($archiveFiles.Count) sessions)" -ForegroundColor Green
        } else {
            Write-Host " ⚠️" -ForegroundColor Yellow
            $warnings += "$corruptedFiles corrupted session files in archive"
        }
    } else {
        Write-Host " ✅" -ForegroundColor Green
    }
    
    # Display results
    Write-Host "`n📋 Results:" -ForegroundColor Cyan
    
    if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
        Write-Host "✅ All systems operational!" -ForegroundColor Green
    } else {
        if ($issues.Count -gt 0) {
            Write-Host "`n❌ Critical Issues:" -ForegroundColor Red
            $issues | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        }
        
        if ($warnings.Count -gt 0) {
            Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
            $warnings | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
        }
        
        Write-Host "`n💡 Run '.\msp.ps1 repair' to fix issues" -ForegroundColor Cyan
    }
    
    Write-Host ""
    
    return @{
        Healthy = $issues.Count -eq 0
        Issues = $issues
        Warnings = $warnings
    }
}

function Repair-MSPIssues {
    <#
    .SYNOPSIS
        Attempts to repair common MSP issues
    #>
    
    Write-Host "`n🔧 MSP Repair Tool" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    $fixed = 0
    $failed = 0
    
    # Create missing directories
    Write-Host "`nCreating directories..." -ForegroundColor Yellow
    $requiredDirs = @(".msp", ".msp\archive", ".msp\errors", ".msp\logs")
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            try {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                Write-Host "  ✅ Created: $dir" -ForegroundColor Green
                $fixed++
            } catch {
                Write-Host "  ❌ Failed: $dir - $_" -ForegroundColor Red
                $failed++
            }
        }
    }
    
    # Fix corrupted session file
    $sessionFile = ".msp\current-session.json"
    if (Test-Path $sessionFile) {
        try {
            $session = Get-Content $sessionFile | ConvertFrom-Json
            # If we can read it, it's not corrupted
        } catch {
            Write-Host "`nFixing corrupted session file..." -ForegroundColor Yellow
            try {
                # Archive the corrupted file
                $backupFile = ".msp\errors\corrupted-session-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
                Copy-Item $sessionFile $backupFile
                Remove-Item $sessionFile -Force
                Write-Host "  ✅ Corrupted session archived" -ForegroundColor Green
                $fixed++
            } catch {
                Write-Host "  ❌ Failed to fix session file" -ForegroundColor Red
                $failed++
            }
        }
    }
    
    # Initialize default config if missing
    if (-not (Test-Path "config\msp-config.json")) {
        Write-Host "`nCreating default configuration..." -ForegroundColor Yellow
        try {
            Initialize-MSPConfig
            Write-Host "  ✅ Configuration created" -ForegroundColor Green
            $fixed++
        } catch {
            Write-Host "  ❌ Failed to create configuration" -ForegroundColor Red
            $failed++
        }
    }
    
    # Clean up old temp files
    Write-Host "`nCleaning temporary files..." -ForegroundColor Yellow
    $tempFiles = Get-ChildItem -Path "." -Filter "msp-test-*.tmp" -ErrorAction SilentlyContinue
    foreach ($file in $tempFiles) {
        try {
            Remove-Item $file.FullName -Force
            $fixed++
        } catch {
            $failed++
        }
    }
    if ($tempFiles.Count -gt 0) {
        Write-Host "  ✅ Cleaned $($tempFiles.Count) temp files" -ForegroundColor Green
    }
    
    # Summary
    Write-Host "`n📊 Repair Summary:" -ForegroundColor Cyan
    Write-Host "  Fixed: $fixed issues" -ForegroundColor Green
    if ($failed -gt 0) {
        Write-Host "  Failed: $failed issues" -ForegroundColor Red
    }
    
    Write-Host "`nRun '.\msp.ps1 validate' to check status" -ForegroundColor Yellow
    Write-Host ""
}

function Get-MSPDiagnostics {
    <#
    .SYNOPSIS
        Collects diagnostic information for troubleshooting
    #>
    
    Write-Host "`n📊 MSP Diagnostics" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    
    $diag = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        System = @{
            PSVersion = $PSVersionTable.PSVersion.ToString()
            OS = [System.Environment]::OSVersion.ToString()
            User = $env:USERNAME
            Computer = $env:COMPUTERNAME
            CurrentDirectory = Get-Location
        }
        MSP = @{
            Version = "1.0.0"  # TODO: Get from manifest
            InstallPath = $PSScriptRoot
            StateDirectory = ".msp"
        }
        Configuration = @{}
        Session = @{}
        Archive = @{}
        Errors = @()
    }
    
    # Get configuration
    try {
        $config = Get-MSPConfig
        $diag.Configuration = @{
            HasObsidian = [bool]$config.obsidian.vaultPath
            HasLinear = [bool]$config.linear.teamId
            HasNeo4j = [bool]$config.neo4j.boltUri
            DebugMode = $config.msp.debugMode
        }
    } catch {
        $diag.Errors += "Failed to load configuration"
    }
    
    # Get session info
    if (Test-Path ".msp\current-session.json") {
        try {
            $session = Get-Content ".msp\current-session.json" | ConvertFrom-Json
            $diag.Session = @{
                Id = $session.id
                Status = $session.status
                StartTime = $session.startTime
                UpdateCount = $session.updates.Count
            }
        } catch {
            $diag.Errors += "Failed to load session"
        }
    }
    
    # Get archive info
    if (Test-Path ".msp\archive") {
        $archiveFiles = Get-ChildItem ".msp\archive" -Filter "*.json"
        $diag.Archive = @{
            SessionCount = $archiveFiles.Count
            OldestSession = ($archiveFiles | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime
            NewestSession = ($archiveFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
            TotalSize = ($archiveFiles | Measure-Object -Property Length -Sum).Sum
        }
    }
    
    # Save diagnostics
    $diagFile = ".msp\diagnostics-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $diag | ConvertTo-Json -Depth 10 | Out-File $diagFile -Encoding UTF8
    
    # Display summary
    Write-Host "`nSystem:" -ForegroundColor Yellow
    Write-Host "  PowerShell: $($diag.System.PSVersion)" -ForegroundColor White
    Write-Host "  OS: $($diag.System.OS)" -ForegroundColor White
    
    Write-Host "`nConfiguration:" -ForegroundColor Yellow
    Write-Host "  Obsidian: $(if($diag.Configuration.HasObsidian) {'✅'} else {'❌'})" -ForegroundColor White
    Write-Host "  Linear: $(if($diag.Configuration.HasLinear) {'✅'} else {'❌'})" -ForegroundColor White
    Write-Host "  Neo4j: $(if($diag.Configuration.HasNeo4j) {'✅'} else {'❌'})" -ForegroundColor White
    
    if ($diag.Session.Id) {
        Write-Host "`nActive Session:" -ForegroundColor Yellow
        Write-Host "  ID: $($diag.Session.Id)" -ForegroundColor White
        Write-Host "  Status: $($diag.Session.Status)" -ForegroundColor White
    }
    
    Write-Host "`nDiagnostics saved to: $diagFile" -ForegroundColor Green
    Write-Host ""
    
    return $diagFile
}

# Export functions
Export-ModuleMember -Function Test-MSPHealth, Repair-MSPIssues, Get-MSPDiagnostics
