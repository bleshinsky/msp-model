# MSP Core Automation
# Handles the main session lifecycle automation

# Import required modules
. "$PSScriptRoot\msp-config.ps1"
. "$PSScriptRoot\msp-error-handler.ps1"

# Import integrations if available
$integrationsPath = Join-Path $PSScriptRoot "..\integrations"
if (Test-Path "$integrationsPath\neo4j\query-builder.ps1") {
    . "$integrationsPath\neo4j\query-builder.ps1"
}
if (Test-Path "$integrationsPath\obsidian\obsidian-integration.ps1") {
    . "$integrationsPath\obsidian\obsidian-integration.ps1"
}
if (Test-Path "$integrationsPath\linear\linear-integration.ps1") {
    . "$integrationsPath\linear\linear-integration.ps1"
}

function Start-MSPSession {
    param(
        [string]$Project = (Get-MSPConfig).project,
        [string]$Description = "",
        [int]$StartProgress = -1
    )
    
    $config = Get-MSPConfig
    $sessionId = "msp-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
    
    # Check for existing active session
    $stateFile = Join-Path $config.paths.stateDir "current-session.json"
    if (Test-Path $stateFile) {
        $existingSession = Get-Content $stateFile | ConvertFrom-Json
        if ($existingSession.status -eq 'active') {
            Write-Warning "Active session found: $($existingSession.id)"
            Write-Host "Run 'msp end' to close it first, or 'msp recover' to continue it"
            return $null
        }
    }
    
    # Get current progress from Neo4j if not specified
    if ($StartProgress -lt 0) {
        Write-Host "Current progress will be determined from project state"
        $StartProgress = 0  # Default, would be queried from Neo4j
    }
    
    # Create session object
    $session = @{
        id = $sessionId
        project = $Project
        startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        endTime = $null
        status = 'active'
        user = $env:USERNAME
        startProgress = $StartProgress
        endProgress = $StartProgress
        updates = @()
        decisions = @()
        entities = @()
        blockers = @()
        queries = @()
    }
    
    # Generate Neo4j query
    $neo4jQuery = New-SessionQuery -SessionId $sessionId -Project $Project -StartProgress $StartProgress
    $session.queries += $neo4jQuery
    
    # Create Obsidian note if configured
    if ($config.obsidian.vaultPath -and (Test-Path $config.obsidian.vaultPath)) {
        try {
            $noteInfo = New-ObsidianDailyNote -Session $session
            Write-Host "📝 Obsidian note prepared: $($noteInfo.path)" -ForegroundColor Green
        } catch {
            Write-MSPLog "Failed to create Obsidian note: $_" -Level Warning
        }
    }
    
    # Save session state
    $session | ConvertTo-Json -Depth 10 | Out-File $stateFile -Encoding UTF8
    
    # Display session start info
    Write-Host "`n🚀 MSP Session Started" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "Session ID: $sessionId" -ForegroundColor White
    Write-Host "Project: $Project" -ForegroundColor White
    Write-Host "Progress: $StartProgress%" -ForegroundColor White
    Write-Host "Time: $(Get-Date -Format 'HH:mm')" -ForegroundColor White
    
    # Show Neo4j query
    Write-Host "`n📊 Neo4j Query (copy to browser):" -ForegroundColor Yellow
    Write-Host $neo4jQuery -ForegroundColor Gray
    
    # Try to copy to clipboard
    try {
        $neo4jQuery | Set-Clipboard
        Write-Host "`n✅ Query copied to clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "`n⚠️  Copy the query manually" -ForegroundColor Yellow
    }
    
    return $session
}

function Update-MSPSession {
    param(
        [Parameter(Mandatory)]
        [string]$Description,
        
        [int]$Progress = -1,
        [string[]]$Tags = @()
    )
    
    $config = Get-MSPConfig
    $stateFile = Join-Path $config.paths.stateDir "current-session.json"
    
    # Load current session
    if (-not (Test-Path $stateFile)) {
        Write-Error "No active session found. Run 'msp start' first."
        return $null
    }
    
    $session = Get-Content $stateFile | ConvertFrom-Json
    
    if ($session.status -ne 'active') {
        Write-Error "Session is not active. Current status: $($session.status)"
        return $null
    }
    
    # Create update object
    $update = @{
        time = Get-Date -Format "HH:mm"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        description = $Description
        progress = $Progress
        tags = $Tags
    }
    
    # Add to session
    $session.updates += $update
    
    # Update progress if specified
    if ($Progress -ge 0) {
        $session.endProgress = $Progress
    }
    
    # Check for decision keywords
    $decisionKeywords = @('decided', 'chose', 'selected', 'will use', 'going with')
    $isDecision = $decisionKeywords | Where-Object { $Description -match $_ }
    
    if ($isDecision) {
        $decision = @{
            content = $Description
            timestamp = $update.timestamp
            rationale = "Captured from update"
        }
        $session.decisions += $decision
        
        # Generate decision query
        $decisionQuery = New-DecisionQuery -SessionId $session.id -Decision $Description
        $session.queries += $decisionQuery
        
        Write-Host "💡 Decision recorded!" -ForegroundColor Yellow
    }
    
    # Check for entity creation keywords
    $entityKeywords = @('created', 'implemented', 'built', 'added', 'set up')
    $isEntity = $entityKeywords | Where-Object { $Description -match $_ }
    
    if ($isEntity -and $Description -match '(\w+\s*\w*)') {
        $entityName = $Matches[1]
        $entity = @{
            name = $entityName
            type = "Component"
            timestamp = $update.timestamp
        }
        $session.entities += $entity
        
        Write-Host "🔧 Entity tracked: $entityName" -ForegroundColor Green
    }
    
    # Generate progress query
    $progressQuery = New-ProgressUpdateQuery -SessionId $session.id -Description $Description -Progress $Progress
    $session.queries += $progressQuery
    
    # Update Obsidian if configured
    if ($config.obsidian.vaultPath) {
        try {
            $obsidianUpdate = Update-ObsidianSessionNote -Update $Description -Progress $Progress
            Write-MSPLog "Obsidian updated" -Level Info
        } catch {
            Write-MSPLog "Failed to update Obsidian: $_" -Level Warning
        }
    }
    
    # Save updated session
    $session | ConvertTo-Json -Depth 10 | Out-File $stateFile -Encoding UTF8
    
    # Display update confirmation
    Write-Host "`n✅ Update recorded" -ForegroundColor Green
    Write-Host "Time: $($update.time)" -ForegroundColor Gray
    Write-Host "Description: $Description" -ForegroundColor White
    if ($Progress -ge 0) {
        Write-Host "Progress: $Progress%" -ForegroundColor Cyan
    }
    
    return $update
}

function Stop-MSPSession {
    param(
        [string]$Summary = ""
    )
    
    $config = Get-MSPConfig
    $stateFile = Join-Path $config.paths.stateDir "current-session.json"
    
    # Load current session
    if (-not (Test-Path $stateFile)) {
        Write-Error "No active session found."
        return $null
    }
    
    $session = Get-Content $stateFile | ConvertFrom-Json
    
    if ($session.status -ne 'active') {
        Write-Warning "Session is not active. Current status: $($session.status)"
        return $null
    }
    
    # Update session
    $session.endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $session.status = 'completed'
    $session.summary = $Summary
    
    # Calculate duration
    $start = [DateTime]::Parse($session.startTime)
    $end = [DateTime]::Parse($session.endTime)
    $duration = $end - $start
    $session.duration = [Math]::Round($duration.TotalHours, 2)
    
    # Generate end session query
    $endQuery = New-SessionEndQuery -SessionId $session.id -EndProgress $session.endProgress -Summary $Summary
    $session.queries += $endQuery
    
    # Generate Linear comment if configured
    if ($config.linear.activeIssue) {
        try {
            $linearComment = New-LinearSessionComment -Session $session
            Write-Host "`n📋 Linear update prepared" -ForegroundColor Green
            Write-Host "Issue: $($linearComment.issueId)" -ForegroundColor Gray
        } catch {
            Write-MSPLog "Failed to generate Linear comment: $_" -Level Warning
        }
    }
    
    # Archive session
    $archiveDir = Join-Path $config.paths.archiveDir "sessions"
    if (-not (Test-Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }
    
    $archivePath = Join-Path $archiveDir "$($session.id).json"
    $session | ConvertTo-Json -Depth 10 | Out-File $archivePath -Encoding UTF8
    
    # Save all queries
    $queriesPath = Join-Path $archiveDir "$($session.id).cypher"
    $session.queries -join "`n`n" | Out-File $queriesPath -Encoding UTF8
    
    # Clear current session
    Remove-Item $stateFile -Force
    
    # Display session summary
    Write-Host "`n🎯 Session Complete!" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    Write-Host "Duration: $($session.duration) hours" -ForegroundColor White
    Write-Host "Updates: $($session.updates.Count)" -ForegroundColor White
    Write-Host "Decisions: $($session.decisions.Count)" -ForegroundColor White
    Write-Host "Progress: $($session.startProgress)% → $($session.endProgress)%" -ForegroundColor Cyan
    
    Write-Host "`n📊 Neo4j Queries saved to:" -ForegroundColor Yellow
    Write-Host $queriesPath -ForegroundColor Gray
    
    return $session
}

function Get-MSPSessionStatus {
    $config = Get-MSPConfig
    $stateFile = Join-Path $config.paths.stateDir "current-session.json"
    
    if (-not (Test-Path $stateFile)) {
        Write-Host "No active session" -ForegroundColor Gray
        return $null
    }
    
    $session = Get-Content $stateFile | ConvertFrom-Json
    
    if ($session.status -eq 'active') {
        $start = [DateTime]::Parse($session.startTime)
        $duration = (Get-Date) - $start
        
        Write-Host "`n📊 Current Session" -ForegroundColor Cyan
        Write-Host "================" -ForegroundColor Cyan
        Write-Host "ID: $($session.id)" -ForegroundColor White
        Write-Host "Project: $($session.project)" -ForegroundColor White
        Write-Host "Duration: $([Math]::Round($duration.TotalHours, 2)) hours" -ForegroundColor White
        Write-Host "Updates: $($session.updates.Count)" -ForegroundColor White
        Write-Host "Progress: $($session.startProgress)% → $($session.endProgress)%" -ForegroundColor Cyan
        
        if ($session.updates.Count -gt 0) {
            Write-Host "`nRecent updates:" -ForegroundColor Yellow
            $session.updates | Select-Object -Last 3 | ForEach-Object {
                Write-Host "  [$($_.time)] $($_.description)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "Session status: $($session.status)" -ForegroundColor Yellow
    }
    
    return $session
}

# Export functions
Export-ModuleMember -Function Start-MSPSession, Update-MSPSession, Stop-MSPSession, Get-MSPSessionStatus
