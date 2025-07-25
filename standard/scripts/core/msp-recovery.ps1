<#
.SYNOPSIS
    MSP session recovery and management
.DESCRIPTION
    Handles crashed sessions, recovery, and session management
#>

# Load dependencies
. "$PSScriptRoot\msp-config.ps1"
. "$PSScriptRoot\msp-error-handler.ps1"
. "$PSScriptRoot\msp-core.ps1"

function Get-MSPSessions {
    <#
    .SYNOPSIS
        Lists all MSP sessions
    .PARAMETER Status
        Filter by status: active, completed, all
    .PARAMETER Limit
        Number of sessions to return
    #>
    param(
        [ValidateSet('active', 'completed', 'all')]
        [string]$Status = 'all',
        
        [int]$Limit = 10
    )
    
    $sessions = @()
    
    # Check for active session
    if ($Status -in @('active', 'all')) {
        if (Test-Path ".msp\current-session.json") {
            try {
                $active = Get-Content ".msp\current-session.json" | ConvertFrom-Json
                if ($active.status -eq 'active') {
                    $sessions += $active
                }
            } catch {
                Write-MSPLog "Error reading active session" -Level Warning
            }
        }
    }
    
    # Get archived sessions
    if ($Status -in @('completed', 'all')) {
        $archiveDir = ".msp\archive"
        if (Test-Path $archiveDir) {
            $archiveFiles = Get-ChildItem $archiveDir -Filter "*.json" | 
                           Sort-Object LastWriteTime -Descending |
                           Select-Object -First $Limit
            
            foreach ($file in $archiveFiles) {
                try {
                    $session = Get-Content $file.FullName | ConvertFrom-Json
                    if ($Status -eq 'all' -or $session.status -eq $Status) {
                        $sessions += $session
                    }
                } catch {
                    Write-MSPLog "Error reading session: $($file.Name)" -Level Warning
                }
            }
        }
    }
    
    return $sessions | Select-Object -First $Limit
}

function Show-MSPSessions {
    <#
    .SYNOPSIS
        Displays MSP sessions in a formatted table
    #>
    param(
        [string]$Status = 'all',
        [int]$Limit = 10
    )
    
    Write-Host "`n📅 MSP Sessions" -ForegroundColor Cyan
    Write-Host "==============" -ForegroundColor Cyan
    
    $sessions = Get-MSPSessions -Status $Status -Limit $Limit
    
    if ($sessions.Count -eq 0) {
        Write-Host "No sessions found" -ForegroundColor Yellow
        return
    }
    
    $sessions | ForEach-Object {
        $statusColor = switch ($_.status) {
            'active' { 'Green' }
            'completed' { 'White' }
            'crashed' { 'Red' }
            default { 'Gray' }
        }
        
        Write-Host "`n$($_.id)" -ForegroundColor $statusColor
        Write-Host "  Project: $($_.project)" -ForegroundColor Gray
        Write-Host "  Status: $($_.status)" -ForegroundColor Gray
        Write-Host "  Started: $($_.startTime)" -ForegroundColor Gray
        
        if ($_.status -eq 'completed') {
            Write-Host "  Duration: $($_.duration) hours" -ForegroundColor Gray
            Write-Host "  Progress: $($_.startProgress)% → $($_.endProgress)%" -ForegroundColor Gray
        } elseif ($_.status -eq 'active') {
            $duration = [Math]::Round((Get-Date - [DateTime]::Parse($_.startTime)).TotalHours, 2)
            Write-Host "  Duration: $duration hours (ongoing)" -ForegroundColor Yellow
        }
        
        if ($_.updates.Count -gt 0) {
            Write-Host "  Updates: $($_.updates.Count)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

function Recover-MSPSession {
    <#
    .SYNOPSIS
        Recovers a crashed or stuck session
    .PARAMETER SessionId
        Specific session to recover
    .PARAMETER Force
        Force recovery without prompts
    #>
    param(
        [string]$SessionId,
        
        [switch]$Force
    )
    
    Write-Host "`n🔧 MSP Session Recovery" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    
    # Find session to recover
    $sessionToRecover = $null
    
    if ($SessionId) {
        # Specific session requested
        if (Test-Path ".msp\current-session.json") {
            $current = Get-Content ".msp\current-session.json" | ConvertFrom-Json
            if ($current.id -eq $SessionId) {
                $sessionToRecover = $current
            }
        }
        
        if (-not $sessionToRecover) {
            # Check archive
            $archiveFile = ".msp\archive\$SessionId.json"
            if (Test-Path $archiveFile) {
                $sessionToRecover = Get-Content $archiveFile | ConvertFrom-Json
            }
        }
        
        if (-not $sessionToRecover) {
            Write-MSPLog "Session not found: $SessionId" -Level Error
            return
        }
    } else {
        # Check for active session
        if (Test-Path ".msp\current-session.json") {
            $sessionToRecover = Get-Content ".msp\current-session.json" | ConvertFrom-Json
        } else {
            Write-MSPLog "No active session to recover" -Level Warning
            Write-Host "Use -SessionId to recover a specific session" -ForegroundColor Yellow
            return
        }
    }
    
    # Display session info
    Write-Host "`nSession to recover:" -ForegroundColor Yellow
    Write-Host "  ID: $($sessionToRecover.id)" -ForegroundColor White
    Write-Host "  Project: $($sessionToRecover.project)" -ForegroundColor White
    Write-Host "  Started: $($sessionToRecover.startTime)" -ForegroundColor White
    Write-Host "  Status: $($sessionToRecover.status)" -ForegroundColor White
    Write-Host "  Updates: $($sessionToRecover.updates.Count)" -ForegroundColor White
    
    # Calculate duration
    $duration = [Math]::Round((Get-Date - [DateTime]::Parse($sessionToRecover.startTime)).TotalHours, 2)
    Write-Host "  Duration: $duration hours" -ForegroundColor White
    
    # Confirm recovery
    if (-not $Force) {
        Write-Host "`nRecovery options:" -ForegroundColor Cyan
        Write-Host "  1. Resume session (continue working)" -ForegroundColor White
        Write-Host "  2. Complete session (end with current state)" -ForegroundColor White
        Write-Host "  3. Discard session (lose all data)" -ForegroundColor White
        Write-Host "  4. Cancel recovery" -ForegroundColor White
        
        $choice = Read-Host "`nSelect option (1-4)"
    } else {
        $choice = "2"  # Default to complete
    }
    
    switch ($choice) {
        "1" {
            # Resume session
            Write-Host "`n✅ Resuming session..." -ForegroundColor Green
            
            # Update status to active
            $sessionToRecover.status = 'active'
            $sessionToRecover | ConvertTo-Json -Depth 10 | Out-File ".msp\current-session.json" -Encoding UTF8
            
            # Set as current session
            $script:CurrentSession = $sessionToRecover
            
            Write-Host "Session resumed. Continue with: .\msp.ps1 update" -ForegroundColor Green
        }
        
        "2" {
            # Complete session
            Write-Host "`n✅ Completing session..." -ForegroundColor Green
            
            # Update session
            $sessionToRecover.endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $sessionToRecover.status = 'completed'
            $sessionToRecover.duration = $duration
            
            # Archive it
            Archive-Session -Session $sessionToRecover
            
            # Generate completion queries
            Write-Host "`n📊 Neo4j Queries to complete session:" -ForegroundColor Yellow
            $endQuery = Get-Neo4jSessionQueries -Action 'end' -SessionId $sessionToRecover.id
            Write-Host $endQuery -ForegroundColor Gray
            
            # Clean up
            if (Test-Path ".msp\current-session.json") {
                Remove-Item ".msp\current-session.json" -Force
            }
            
            Write-Host "`n✅ Session recovered and completed" -ForegroundColor Green
        }
        
        "3" {
            # Discard session
            Write-Host "`n⚠️  Are you sure? This will lose all session data!" -ForegroundColor Red
            $confirm = Read-Host "Type 'DISCARD' to confirm"
            
            if ($confirm -eq 'DISCARD') {
                # Archive as crashed
                $sessionToRecover.status = 'crashed'
                $crashFile = ".msp\errors\crashed-$($sessionToRecover.id).json"
                $sessionToRecover | ConvertTo-Json -Depth 10 | Out-File $crashFile -Encoding UTF8
                
                # Clean up
                if (Test-Path ".msp\current-session.json") {
                    Remove-Item ".msp\current-session.json" -Force
                }
                
                Write-Host "❌ Session discarded" -ForegroundColor Red
            } else {
                Write-Host "Recovery cancelled" -ForegroundColor Yellow
            }
        }
        
        default {
            Write-Host "Recovery cancelled" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
}

function Export-MSPSession {
    <#
    .SYNOPSIS
        Exports session data for backup or analysis
    .PARAMETER SessionId
        Session to export (default: current)
    .PARAMETER Format
        Export format: json, markdown, neo4j
    #>
    param(
        [string]$SessionId,
        
        [ValidateSet('json', 'markdown', 'neo4j')]
        [string]$Format = 'json'
    )
    
    # Get session
    $session = $null
    if ($SessionId) {
        $sessions = Get-MSPSessions -Status 'all' -Limit 100
        $session = $sessions | Where-Object { $_.id -eq $SessionId } | Select-Object -First 1
    } else {
        $session = Get-CurrentSession
    }
    
    if (-not $session) {
        Write-MSPLog "No session found" -Level Error
        return
    }
    
    $exportDir = ".msp\exports"
    if (-not (Test-Path $exportDir)) {
        New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
    }
    
    $exportFile = Join-Path $exportDir "$($session.id).$Format"
    
    switch ($Format) {
        'json' {
            $session | ConvertTo-Json -Depth 10 | Out-File $exportFile -Encoding UTF8
        }
        
        'markdown' {
            $markdown = @"
# MSP Session: $($session.id)

## Summary
- **Project**: $($session.project)
- **Date**: $(Get-Date $session.startTime -Format "yyyy-MM-dd")
- **Duration**: $($session.duration) hours
- **Progress**: $($session.startProgress)% → $($session.endProgress)%
- **Status**: $($session.status)

## Updates
$(($session.updates | ForEach-Object {
"### [$($_.time)] $($_.description)
Progress: $($_.progress)%
"
}) -join "`n")

## Decisions
$(($session.decisions | ForEach-Object { "- $_" }) -join "`n")

## Blockers
$(($session.blockers | ForEach-Object { "- $_" }) -join "`n")

---
*Exported by MSP on $(Get-Date -Format "yyyy-MM-dd HH:mm")*
"@
            $markdown | Out-File $exportFile -Encoding UTF8
        }
        
        'neo4j' {
            $queries = @()
            
            # Session creation
            $queries += Get-Neo4jSessionQueries -Action 'start' -SessionId $session.id -Parameters @{
                project = $session.project
                progress = $session.startProgress
            }
            
            # Updates
            foreach ($update in $session.updates) {
                $queries += Get-Neo4jSessionQueries -Action 'update' -SessionId $session.id -Parameters @{
                    message = $update.description
                    progress = $update.progress
                }
            }
            
            # Session end
            if ($session.status -eq 'completed') {
                $queries += Get-Neo4jSessionQueries -Action 'end' -SessionId $session.id
            }
            
            $queries -join "`n`n" | Out-File $exportFile -Encoding UTF8
        }
    }
    
    Write-Host "✅ Session exported to: $exportFile" -ForegroundColor Green
    
    # Try to copy to clipboard
    if ($Format -eq 'neo4j') {
        try {
            Get-Content $exportFile | Set-Clipboard
            Write-Host "📋 Queries copied to clipboard!" -ForegroundColor Green
        } catch {
            # Clipboard not available
        }
    }
    
    return $exportFile
}

# Export functions
Export-ModuleMember -Function Get-MSPSessions, Show-MSPSessions, Recover-MSPSession, Export-MSPSession
