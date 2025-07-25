#Requires -Version 7.0
<#
.SYNOPSIS
    MSP Lite - Zero-dependency session tracking for developers
.DESCRIPTION
    A lightweight implementation of the Mandatory Session Protocol.
    No external dependencies required - just PowerShell and JSON files.
.EXAMPLE
    msp-lite start
    msp-lite update "Implemented user authentication" 25
    msp-lite end
.NOTES
    Version: 1.0.0
    License: MIT
#>

param(
    [Parameter(Position=0)]
    [ValidateSet('start', 'update', 'end', 'status', 'recall', 'context', 'help')]
    [string]$Command = 'help',
    
    [Parameter(Position=1)]
    [string]$Message = '',
    
    [Parameter(Position=2)]
    [int]$Progress = -1
)

# Configuration
$script:Config = @{
    StateDir = Join-Path $env:USERPROFILE '.msp-lite'
    SessionFile = 'current-session.json'
    ArchiveDir = 'archive'
    HistoryFile = 'session-history.json'
    DecisionsFile = 'decisions.json'
    ProgressFile = 'progress-tracking.json'
    DateFormat = 'yyyy-MM-dd'
    TimeFormat = 'HH:mm:ss'
}

# Ensure state directory exists
function Initialize-MSPLite {
    if (-not (Test-Path $script:Config.StateDir)) {
        New-Item -ItemType Directory -Path $script:Config.StateDir -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:Config.StateDir $script:Config.ArchiveDir) -Force | Out-Null
        
        # Create initial files
        @{} | ConvertTo-Json | Out-File (Join-Path $script:Config.StateDir $script:Config.HistoryFile) -Encoding UTF8
        @() | ConvertTo-Json | Out-File (Join-Path $script:Config.StateDir $script:Config.DecisionsFile) -Encoding UTF8
        @{} | ConvertTo-Json | Out-File (Join-Path $script:Config.StateDir $script:Config.ProgressFile) -Encoding UTF8
    }
}

# Load current session
function Get-CurrentSession {
    $sessionPath = Join-Path $script:Config.StateDir $script:Config.SessionFile
    if (Test-Path $sessionPath) {
        return Get-Content $sessionPath | ConvertFrom-Json
    }
    return $null
}

# Save session
function Save-Session {
    param($Session)
    $sessionPath = Join-Path $script:Config.StateDir $script:Config.SessionFile
    $Session | ConvertTo-Json -Depth 10 | Out-File $sessionPath -Encoding UTF8
}

# Start new session
function Start-Session {
    $currentSession = Get-CurrentSession
    if ($currentSession -and $currentSession.status -eq 'active') {
        Write-Host "❌ Session already active! End it first with: msp-lite end" -ForegroundColor Red
        return
    }
    
    $sessionId = "msp-lite-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $session = @{
        id = $sessionId
        startTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        status = 'active'
        updates = @()
        decisions = @()
        progress = 0
        context = @{
            user = $env:USERNAME
            machine = $env:COMPUTERNAME
            directory = $PWD.Path
        }
    }
    
    Save-Session $session
    
    # Show last session summary if exists
    $history = Get-SessionHistory
    $lastSession = $history | Select-Object -Last 1
    
    Write-Host "🚀 MSP Lite Session Started" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host "Session ID: $sessionId" -ForegroundColor Gray
    Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Write-Host "Directory: $($PWD.Path)" -ForegroundColor Gray
    
    if ($lastSession) {
        Write-Host "`n📊 Last Session Summary:" -ForegroundColor Yellow
        Write-Host "Date: $($lastSession.date)" -ForegroundColor White
        Write-Host "Duration: $($lastSession.duration)" -ForegroundColor White
        Write-Host "Progress: $($lastSession.progress)%" -ForegroundColor White
        Write-Host "Updates: $($lastSession.updateCount)" -ForegroundColor White
    }
    
    Write-Host "`n✅ Ready to track your work!" -ForegroundColor Green
    Write-Host "Use 'msp-lite update ""message"" [progress]' to track" -ForegroundColor Gray
}

# Update session
function Update-Session {
    param(
        [string]$Message,
        [int]$Progress
    )
    
    $session = Get-CurrentSession
    if (-not $session -or $session.status -ne 'active') {
        Write-Host "❌ No active session! Start one with: msp-lite start" -ForegroundColor Red
        return
    }
    
    $update = @{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        message = $Message
        progress = if ($Progress -ge 0) { $Progress } else { $null }
    }
    
    # Add update to session
    $session.updates += $update
    
    # Update overall progress
    if ($Progress -ge 0) {
        $session.progress = $Progress
    }
    
    # Check for decision keywords
    $decisionKeywords = @('decided', 'chose', 'selected', 'picked', 'will use', 'going with')
    $isDecision = $decisionKeywords | Where-Object { $Message -match $_ }
    
    if ($isDecision) {
        $decision = @{
            timestamp = $update.timestamp
            content = $Message
            sessionId = $session.id
        }
        $session.decisions += $decision
        
        # Also save to global decisions file
        $decisionsPath = Join-Path $script:Config.StateDir $script:Config.DecisionsFile
        $allDecisions = if (Test-Path $decisionsPath) {
            Get-Content $decisionsPath | ConvertFrom-Json
        } else { @() }
        $allDecisions += $decision
        $allDecisions | ConvertTo-Json -Depth 10 | Out-File $decisionsPath -Encoding UTF8
    }
    
    Save-Session $session
    
    Write-Host "✅ Update recorded" -ForegroundColor Green
    if ($Progress -ge 0) {
        Write-Host "📊 Progress: $Progress%" -ForegroundColor Cyan
    }
    if ($isDecision) {
        Write-Host "💡 Decision tracked!" -ForegroundColor Yellow
    }
}

# End session
function End-Session {
    $session = Get-CurrentSession
    if (-not $session -or $session.status -ne 'active') {
        Write-Host "❌ No active session to end!" -ForegroundColor Red
        return
    }
    
    $session.endTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $session.status = 'completed'
    
    # Calculate duration
    $start = [DateTime]::Parse($session.startTime)
    $end = [DateTime]::Parse($session.endTime)
    $duration = $end - $start
    $session.duration = "{0:hh\:mm\:ss}" -f $duration
    
    # Archive session
    $archivePath = Join-Path $script:Config.StateDir $script:Config.ArchiveDir
    $archiveFile = Join-Path $archivePath "$($session.id).json"
    $session | ConvertTo-Json -Depth 10 | Out-File $archiveFile -Encoding UTF8
    
    # Update history
    $historyPath = Join-Path $script:Config.StateDir $script:Config.HistoryFile
    $history = if (Test-Path $historyPath) {
        Get-Content $historyPath | ConvertFrom-Json
    } else { @{} }
    
    $historySummary = @{
        id = $session.id
        date = Get-Date -Format $script:Config.DateFormat
        duration = $session.duration
        progress = $session.progress
        updateCount = $session.updates.Count
        decisionCount = $session.decisions.Count
    }
    
    # Convert history to array if needed
    if ($history -is [PSCustomObject]) {
        $history = @()
    }
    $history += $historySummary
    $history | ConvertTo-Json -Depth 10 | Out-File $historyPath -Encoding UTF8
    
    # Update progress tracking
    $progressPath = Join-Path $script:Config.StateDir $script:Config.ProgressFile
    $progressData = if (Test-Path $progressPath) {
        Get-Content $progressPath | ConvertFrom-Json
    } else { @{} }
    
    $today = Get-Date -Format $script:Config.DateFormat
    if (-not $progressData.PSObject.Properties[$today]) {
        $progressData | Add-Member -NotePropertyName $today -NotePropertyValue @{
            sessions = 0
            totalProgress = 0
            decisions = 0
        }
    }
    
    $progressData.$today.sessions++
    $progressData.$today.totalProgress = $session.progress
    $progressData.$today.decisions += $session.decisions.Count
    
    $progressData | ConvertTo-Json -Depth 10 | Out-File $progressPath -Encoding UTF8
    
    # Clear current session
    Remove-Item (Join-Path $script:Config.StateDir $script:Config.SessionFile) -Force
    
    # Display summary
    Write-Host "`n📊 Session Complete!" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host "Duration: $($session.duration)" -ForegroundColor White
    Write-Host "Progress: $($session.progress)%" -ForegroundColor White
    Write-Host "Updates: $($session.updates.Count)" -ForegroundColor White
    Write-Host "Decisions: $($session.decisions.Count)" -ForegroundColor White
    
    if ($session.updates.Count -gt 0) {
        Write-Host "`n📝 Key Updates:" -ForegroundColor Yellow
        $session.updates | Select-Object -Last 3 | ForEach-Object {
            Write-Host "  - $($_.message)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n✅ Session archived: $archiveFile" -ForegroundColor Green
}

# Show status
function Show-Status {
    $session = Get-CurrentSession
    
    if (-not $session -or $session.status -ne 'active') {
        Write-Host "📊 No active session" -ForegroundColor Yellow
        
        # Show recent history
        $history = Get-SessionHistory
        if ($history -and $history.Count -gt 0) {
            Write-Host "`n📅 Recent Sessions:" -ForegroundColor Cyan
            $history | Select-Object -Last 5 | ForEach-Object {
                Write-Host "  $($_.date) - Duration: $($_.duration), Progress: $($_.progress)%" -ForegroundColor Gray
            }
        }
        return
    }
    
    $start = [DateTime]::Parse($session.startTime)
    $duration = (Get-Date) - $start
    
    Write-Host "📊 Active Session Status" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host "Session ID: $($session.id)" -ForegroundColor White
    Write-Host "Started: $($session.startTime)" -ForegroundColor White
    Write-Host "Duration: $("{0:hh\:mm\:ss}" -f $duration)" -ForegroundColor White
    Write-Host "Progress: $($session.progress)%" -ForegroundColor White
    Write-Host "Updates: $($session.updates.Count)" -ForegroundColor White
    Write-Host "Decisions: $($session.decisions.Count)" -ForegroundColor White
    
    if ($session.updates.Count -gt 0) {
        Write-Host "`n📝 Recent Updates:" -ForegroundColor Yellow
        $session.updates | Select-Object -Last 3 | ForEach-Object {
            $time = ([DateTime]::Parse($_.timestamp)).ToString('HH:mm')
            Write-Host "  [$time] $($_.message)" -ForegroundColor Gray
            if ($_.progress) {
                Write-Host "         Progress: $($_.progress)%" -ForegroundColor DarkGray
            }
        }
    }
}

# Recall context
function Show-Recall {
    $history = Get-SessionHistory
    $decisions = Get-AllDecisions
    
    Write-Host "🧠 Context Recall" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    
    # Recent work
    if ($history -and $history.Count -gt 0) {
        Write-Host "`n📅 Recent Work:" -ForegroundColor Yellow
        $history | Select-Object -Last 7 | ForEach-Object {
            Write-Host "  $($_.date): $($_.progress)% progress ($($_.updateCount) updates)" -ForegroundColor White
        }
    }
    
    # Recent decisions
    if ($decisions -and $decisions.Count -gt 0) {
        Write-Host "`n💡 Recent Decisions:" -ForegroundColor Yellow
        $decisions | Select-Object -Last 5 | ForEach-Object {
            Write-Host "  - $($_.content)" -ForegroundColor White
            Write-Host "    $($_.timestamp)" -ForegroundColor Gray
        }
    }
    
    # Progress trends
    $progressData = Get-ProgressData
    if ($progressData) {
        Write-Host "`n📈 Progress Trends:" -ForegroundColor Yellow
        $dates = $progressData.PSObject.Properties.Name | Sort-Object | Select-Object -Last 7
        foreach ($date in $dates) {
            $data = $progressData.$date
            Write-Host "  $date: $($data.totalProgress)% ($($data.sessions) sessions)" -ForegroundColor White
        }
    }
}

# Export context
function Export-Context {
    $session = Get-CurrentSession
    $history = Get-SessionHistory
    $decisions = Get-AllDecisions
    
    $context = @"
MSP LITE CONTEXT EXPORT
======================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

CURRENT STATE:
$(if ($session -and $session.status -eq 'active') {
    "Active Session: $($session.id)
Started: $($session.startTime)
Progress: $($session.progress)%
Updates: $($session.updates.Count)"
} else {
    "No active session"
})

RECENT SESSIONS:
$($history | Select-Object -Last 10 | ForEach-Object {
    "$($_.date): Progress $($_.progress)%, Duration $($_.duration)"
} | Out-String)

KEY DECISIONS:
$($decisions | Select-Object -Last 20 | ForEach-Object {
    "- $($_.content)
  Date: $($_.timestamp)"
} | Out-String)

CURRENT DIRECTORY: $($PWD.Path)
"@
    
    # Copy to clipboard if possible
    try {
        $context | Set-Clipboard
        Write-Host "✅ Context copied to clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "📋 Context ready (clipboard not available):" -ForegroundColor Yellow
    }
    
    Write-Host $context -ForegroundColor White
    
    # Also save to file
    $exportPath = Join-Path $script:Config.StateDir "context-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $context | Out-File $exportPath -Encoding UTF8
    Write-Host "`n📁 Saved to: $exportPath" -ForegroundColor Gray
}

# Helper functions
function Get-SessionHistory {
    $historyPath = Join-Path $script:Config.StateDir $script:Config.HistoryFile
    if (Test-Path $historyPath) {
        $data = Get-Content $historyPath | ConvertFrom-Json
        if ($data -is [PSCustomObject]) {
            return @()
        }
        return $data
    }
    return @()
}

function Get-AllDecisions {
    $decisionsPath = Join-Path $script:Config.StateDir $script:Config.DecisionsFile
    if (Test-Path $decisionsPath) {
        return Get-Content $decisionsPath | ConvertFrom-Json
    }
    return @()
}

function Get-ProgressData {
    $progressPath = Join-Path $script:Config.StateDir $script:Config.ProgressFile
    if (Test-Path $progressPath) {
        return Get-Content $progressPath | ConvertFrom-Json
    }
    return @{}
}

# Show help
function Show-Help {
    Write-Host @"
MSP Lite - Mandatory Session Protocol (Lightweight Edition)
=========================================================

A zero-dependency session tracking tool for developers.

USAGE:
    msp-lite <command> [arguments]

COMMANDS:
    start              Start a new session
    update <msg> [%]   Update session with message and optional progress
    end                End current session
    status             Show current session status
    recall             Show context from previous sessions
    context            Export full context for AI
    help               Show this help

EXAMPLES:
    msp-lite start
    msp-lite update "Implemented user authentication" 25
    msp-lite update "Fixed validation bug"
    msp-lite end

FEATURES:
    ✓ Zero dependencies - just PowerShell
    ✓ Automatic decision detection
    ✓ Progress tracking
    ✓ Session history
    ✓ Context export for AI

DATA LOCATION:
    $($script:Config.StateDir)

Learn more at: https://sessionprotocol.dev
"@ -ForegroundColor Cyan
}

# Main execution
Initialize-MSPLite

switch ($Command) {
    'start' { Start-Session }
    'update' { 
        if (-not $Message) {
            Write-Host "❌ Please provide a message: msp-lite update ""your message"" [progress]" -ForegroundColor Red
        } else {
            Update-Session -Message $Message -Progress $Progress
        }
    }
    'end' { End-Session }
    'status' { Show-Status }
    'recall' { Show-Recall }
    'context' { Export-Context }
    'help' { Show-Help }
    default { Show-Help }
}
