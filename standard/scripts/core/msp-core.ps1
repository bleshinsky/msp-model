<#
.SYNOPSIS
    Core MSP engine for session management
.DESCRIPTION
    Handles session lifecycle, state management, and integration orchestration
#>

# Load dependencies
. "$PSScriptRoot\msp-config.ps1"
. "$PSScriptRoot\msp-error-handler.ps1"

# Session state management
$script:CurrentSession = $null
$script:StateFile = ".msp\current-session.json"

function Start-MSPSession {
    <#
    .SYNOPSIS
        Starts a new MSP session
    .PARAMETER Project
        Project name (defaults to config)
    .PARAMETER Progress
        Starting progress percentage
    #>
    param(
        [string]$Project,
        [int]$Progress = -1
    )
    
    # Check prerequisites
    if (-not (Test-MSPPrerequisites)) {
        return
    }
    
    # Check for existing session
    if (Test-Path $script:StateFile) {
        $existing = Get-Content $script:StateFile | ConvertFrom-Json
        if ($existing.status -eq 'active') {
            Write-MSPLog "Session already active: $($existing.id)" -Level Warning
            Write-MSPLog "Run '.\msp.ps1 end' to close it first" -Level Warning
            return
        }
    }
    
    # Get configuration
    $config = Get-MSPConfig
    if (-not $Project) {
        $Project = $config.msp.defaultProject
        if (-not $Project) {
            $Project = Split-Path (Get-Location) -Leaf
        }
    }
    
    # Determine starting progress
    if ($Progress -lt 0) {
        # Try to get from previous session
        $Progress = Get-LastSessionProgress -Project $Project
    }
    
    # Create session
    $session = @{
        id = "msp-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
        startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        project = $Project
        status = 'active'
        startProgress = $Progress
        endProgress = $Progress
        updates = @()
        decisions = @()
        blockers = @()
        nextSteps = @()
    }
    
    # Save state
    Save-SessionState -Session $session
    $script:CurrentSession = $session
    
    # Display session info
    Write-Host "`n🚀 MSP Session Started" -ForegroundColor Green
    Write-Host "====================" -ForegroundColor Green
    Write-Host "ID: $($session.id)" -ForegroundColor White
    Write-Host "Project: $($session.project)" -ForegroundColor White
    Write-Host "Progress: $($session.startProgress)%" -ForegroundColor White
    Write-Host "Time: $($session.startTime)" -ForegroundColor White
    
    # Generate Neo4j query
    Write-Host "`n📊 Neo4j Query:" -ForegroundColor Yellow
    $neo4jQuery = Get-Neo4jSessionQueries -Action 'start' -SessionId $session.id -Parameters @{
        project = $session.project
        progress = $session.startProgress
    }
    Write-Host $neo4jQuery -ForegroundColor Gray
    
    # Copy to clipboard if available
    try {
        $neo4jQuery | Set-Clipboard
        Write-Host "`n✅ Query copied to clipboard!" -ForegroundColor Green
    } catch {
        # Clipboard not available
    }
    
    # Show integrations status
    Show-IntegrationStatus
    
    Write-Host "`n💡 Track your work with: .\msp.ps1 update 'description' [progress%]" -ForegroundColor Cyan
    Write-Host ""
}

function Update-MSPSession {
    <#
    .SYNOPSIS
        Updates current session with progress
    .PARAMETER Notes
        Update description
    .PARAMETER Progress
        New progress percentage (-1 to skip)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Notes,
        
        [int]$Progress = -1
    )
    
    # Load current session
    $session = Get-CurrentSession
    if (-not $session) {
        Write-MSPLog "No active session. Run: .\msp.ps1 start" -Level Error
        return
    }
    
    # Create update
    $update = @{
        time = Get-Date -Format "HH:mm"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        description = $Notes
        progress = $Progress
    }
    
    # Add to session
    $session.updates += $update
    
    # Update progress if provided
    if ($Progress -ge 0) {
        $session.endProgress = $Progress
    }
    
    # Check for keywords
    if ($Notes -match '\b(decided?|chose|selected|going with)\b') {
        $session.decisions += $Notes
    }
    
    if ($Notes -match '\b(blocked|issue|problem|stuck)\b') {
        $session.blockers += $Notes
    }
    
    # Save state
    Save-SessionState -Session $session
    $script:CurrentSession = $session
    
    # Display update
    Write-Host "✅ Update recorded" -ForegroundColor Green
    if ($Progress -ge 0) {
        Write-Host "📊 Progress: $Progress%" -ForegroundColor Cyan
    }
    
    # Check for significant updates
    $config = Get-MSPConfig
    if ($config.linear.activeIssue -and 
        ($Progress -ge 0 -or $Notes -match ($config.linear.significantKeywords -join '|'))) {
        Write-Host "`n💡 Consider updating Linear:" -ForegroundColor Yellow
        Write-Host "   Ask Claude: 'Add comment to $($config.linear.activeIssue): $Notes'" -ForegroundColor Gray
    }
}

function Stop-MSPSession {
    <#
    .SYNOPSIS
        Ends the current MSP session
    .PARAMETER Summary
        Optional session summary
    #>
    param(
        [string]$Summary
    )
    
    # Load current session
    $session = Get-CurrentSession
    if (-not $session) {
        Write-MSPLog "No active session to end" -Level Warning
        return
    }
    
    # Calculate duration
    $startTime = [DateTime]::Parse($session.startTime)
    $duration = [Math]::Round((Get-Date - $startTime).TotalHours, 2)
    
    # Update session
    $session.endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $session.status = 'completed'
    $session.duration = $duration
    if ($Summary) {
        $session.summary = $Summary
    }
    
    # Display summary
    Write-Host "`n🏁 Session Complete!" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    Write-Host "Duration: $duration hours" -ForegroundColor White
    Write-Host "Progress: $($session.startProgress)% → $($session.endProgress)%" -ForegroundColor White
    Write-Host "Updates: $($session.updates.Count)" -ForegroundColor White
    Write-Host "Decisions: $($session.decisions.Count)" -ForegroundColor White
    
    # Generate queries
    Write-Host "`n📊 Neo4j Queries:" -ForegroundColor Yellow
    
    # Session end query
    $endQuery = Get-Neo4jSessionQueries -Action 'end' -SessionId $session.id
    Write-Host "// 1. End session" -ForegroundColor Gray
    Write-Host $endQuery -ForegroundColor Gray
    
    # Progress updates
    if ($session.updates.Count -gt 0) {
        Write-Host "`n// 2. Progress updates" -ForegroundColor Gray
        foreach ($update in $session.updates) {
            $updateQuery = Get-Neo4jSessionQueries -Action 'update' -SessionId $session.id -Parameters @{
                message = $update.description
                progress = $update.progress
            }
            Write-Host $updateQuery -ForegroundColor Gray
        }
    }
    
    # Create Obsidian note
    $config = Get-MSPConfig
    if ($config.obsidian.vaultPath) {
        Write-Host "`n📝 Creating Obsidian note..." -ForegroundColor Yellow
        . "$PSScriptRoot\..\integrations\obsidian\obsidian-integration.ps1"
        $notePath = New-ObsidianDailyNote -Session $session
        if ($notePath) {
            Write-Host "Note created: $notePath" -ForegroundColor Green
        }
    }
    
    # Archive session
    Archive-Session -Session $session
    
    # Clear current session
    if (Test-Path $script:StateFile) {
        Remove-Item $script:StateFile -Force
    }
    $script:CurrentSession = $null
    
    Write-Host "`n✨ Great work! Session archived." -ForegroundColor Green
    Write-Host ""
}

function Get-MSPStatus {
    <#
    .SYNOPSIS
        Shows current MSP status
    #>
    
    $session = Get-CurrentSession
    
    if (-not $session) {
        Write-Host "`n📊 No active session" -ForegroundColor Yellow
        Write-Host "Run: .\msp.ps1 start" -ForegroundColor White
        
        # Show recent sessions
        $archiveDir = ".msp\archive"
        if (Test-Path $archiveDir) {
            $recent = Get-ChildItem $archiveDir -Filter "*.json" | 
                      Sort-Object LastWriteTime -Descending | 
                      Select-Object -First 5
            
            if ($recent) {
                Write-Host "`n📅 Recent Sessions:" -ForegroundColor Cyan
                foreach ($file in $recent) {
                    $s = Get-Content $file.FullName | ConvertFrom-Json
                    Write-Host "  - $($s.id): $($s.project) ($($s.duration)h)" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "`n🚀 Active Session" -ForegroundColor Green
        Write-Host "===============" -ForegroundColor Green
        Write-Host "ID: $($session.id)" -ForegroundColor White
        Write-Host "Project: $($session.project)" -ForegroundColor White
        Write-Host "Started: $($session.startTime)" -ForegroundColor White
        Write-Host "Progress: $($session.startProgress)% → $($session.endProgress)%" -ForegroundColor White
        Write-Host "Updates: $($session.updates.Count)" -ForegroundColor White
        
        if ($session.updates.Count -gt 0) {
            Write-Host "`n📝 Recent Updates:" -ForegroundColor Cyan
            $session.updates | Select-Object -Last 3 | ForEach-Object {
                Write-Host "  [$($_.time)] $($_.description)" -ForegroundColor Gray
            }
        }
        
        # Calculate duration
        $duration = [Math]::Round((Get-Date - [DateTime]::Parse($session.startTime)).TotalHours, 2)
        Write-Host "`n⏱️  Duration: $duration hours" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Helper functions
function Get-CurrentSession {
    if ($script:CurrentSession) {
        return $script:CurrentSession
    }
    
    if (Test-Path $script:StateFile) {
        $script:CurrentSession = Get-Content $script:StateFile | ConvertFrom-Json
        return $script:CurrentSession
    }
    
    return $null
}

function Save-SessionState {
    param($Session)
    
    $stateDir = Split-Path $script:StateFile -Parent
    if (-not (Test-Path $stateDir)) {
        New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    }
    
    $Session | ConvertTo-Json -Depth 10 | Out-File $script:StateFile -Encoding UTF8
}

function Archive-Session {
    param($Session)
    
    $archiveDir = ".msp\archive"
    if (-not (Test-Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }
    
    $archiveFile = Join-Path $archiveDir "$($Session.id).json"
    $Session | ConvertTo-Json -Depth 10 | Out-File $archiveFile -Encoding UTF8
}

function Get-LastSessionProgress {
    param($Project)
    
    $archiveDir = ".msp\archive"
    if (-not (Test-Path $archiveDir)) {
        return 0
    }
    
    $sessions = Get-ChildItem $archiveDir -Filter "*.json" | 
                ForEach-Object {
                    Get-Content $_.FullName | ConvertFrom-Json
                } |
                Where-Object { $_.project -eq $Project -and $_.status -eq 'completed' } |
                Sort-Object endTime -Descending |
                Select-Object -First 1
    
    if ($sessions) {
        return $sessions.endProgress
    }
    
    return 0
}

function Show-IntegrationStatus {
    $config = Get-MSPConfig
    
    Write-Host "`n🔗 Integration Status:" -ForegroundColor Cyan
    
    # Neo4j
    Write-Host "  Neo4j: " -NoNewline
    if ($config.neo4j.boltUri) {
        Write-Host "Configured" -ForegroundColor Green
    } else {
        Write-Host "Not configured (.\msp.ps1 neo4j setup)" -ForegroundColor Yellow
    }
    
    # Obsidian
    Write-Host "  Obsidian: " -NoNewline
    if ($config.obsidian.vaultPath -and (Test-Path $config.obsidian.vaultPath)) {
        Write-Host "Ready" -ForegroundColor Green
    } else {
        Write-Host "Not configured (.\msp.ps1 obsidian setup)" -ForegroundColor Yellow
    }
    
    # Linear
    Write-Host "  Linear: " -NoNewline
    if ($config.linear.teamId -and $config.linear.projectId) {
        Write-Host "Ready" -ForegroundColor Green
        if ($config.linear.activeIssue) {
            Write-Host "    Active Issue: $($config.linear.activeIssue)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Not configured (.\msp.ps1 linear setup)" -ForegroundColor Yellow
    }
}

# Export functions
Export-ModuleMember -Function Start-MSPSession, Update-MSPSession, Stop-MSPSession, Get-MSPStatus, Get-CurrentSession
