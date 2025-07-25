# MSP Neo4j Query Builder
# Generates Cypher queries for MSP operations

function New-SessionQuery {
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [string]$User = $env:USERNAME,
        [string]$Project = "Current Project",
        [int]$StartProgress = 0
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    @"
// Create new session
CREATE (s:Session {
    id: '$SessionId',
    name: 'MSP Session $(Get-Date -Format "yyyy-MM-dd")',
    user: '$User',
    project: '$Project',
    startTime: datetime('$timestamp'),
    date: date(),
    status: 'active',
    progress: $StartProgress
})
RETURN s;
"@
}

function New-ProgressUpdateQuery {
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [Parameter(Mandatory)]
        [string]$Description,
        
        [int]$Progress = -1
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $progressUpdate = if ($Progress -ge 0) {
        ", s.progress = $Progress"
    } else { "" }
    
    @"
// Update session progress
MATCH (s:Session {id: '$SessionId'})
SET s.lastUpdate = datetime('$timestamp')$progressUpdate
CREATE (p:Progress {
    timestamp: datetime('$timestamp'),
    description: '$Description',
    percentage: $(if ($Progress -ge 0) { $Progress } else { 'null' })
})
CREATE (s)-[:HAS_PROGRESS]->(p)
RETURN s, p;
"@
}

function New-DecisionQuery {
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [Parameter(Mandatory)]
        [string]$Decision,
        
        [string]$Rationale = "",
        [string[]]$Alternatives = @()
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    @"
// Create decision
MATCH (s:Session {id: '$SessionId'})
CREATE (d:Decision {
    content: '$Decision',
    rationale: '$Rationale',
    timestamp: datetime('$timestamp'),
    date: date()
})
CREATE (s)-[:MADE_DECISION]->(d)
$(if ($Alternatives.Count -gt 0) {
    $Alternatives | ForEach-Object {
        "CREATE (d)-[:CONSIDERED]->(:Alternative {name: '$_'})"
    } | Join-String -Separator "`n"
})
RETURN s, d;
"@
}

function New-EntityQuery {
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [Parameter(Mandatory)]
        [string]$EntityName,
        
        [string]$EntityType = "Component",
        [hashtable]$Properties = @{}
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $propString = if ($Properties.Count -gt 0) {
        ", " + ($Properties.GetEnumerator() | ForEach-Object {
            "$($_.Key): '$($_.Value)'"
        } | Join-String -Separator ", ")
    } else { "" }
    
    @"
// Create entity
MATCH (s:Session {id: '$SessionId'})
CREATE (e:Entity {
    name: '$EntityName',
    type: '$EntityType',
    createdAt: datetime('$timestamp')$propString
})
CREATE (s)-[:CREATED_ENTITY]->(e)
RETURN s, e;
"@
}

function New-SessionEndQuery {
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [int]$EndProgress = -1,
        [string]$Summary = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    @"
// End session
MATCH (s:Session {id: '$SessionId'})
SET s.endTime = datetime('$timestamp'),
    s.status = 'completed'
    $(if ($EndProgress -ge 0) { ", s.progress = $EndProgress" })
    $(if ($Summary) { ", s.summary = '$Summary'" })

// Calculate duration
WITH s, duration.between(s.startTime, s.endTime) as dur
SET s.duration = dur.hours + (dur.minutes / 60.0)

// Update project state
MATCH (ps:ProjectState {name: '$(Get-MSPConfig).neo4j.projectStateName'})
SET ps.lastUpdated = datetime('$timestamp'),
    ps.progress = $(if ($EndProgress -ge 0) { $EndProgress } else { "ps.progress" }),
    ps.observations = ps.observations + ['Session $SessionId completed']

RETURN s, ps;
"@
}

function Get-SessionContextQuery {
    param(
        [string]$Project = "Current Project",
        [int]$DaysBack = 7
    )
    
    @"
// Get session context
MATCH (ps:ProjectState {project: '$Project'})
OPTIONAL MATCH (s:Session)
WHERE s.project = '$Project' 
  AND s.date > date() - duration({days: $DaysBack})
OPTIONAL MATCH (s)-[:MADE_DECISION]->(d:Decision)
OPTIONAL MATCH (s)-[:CREATED_ENTITY]->(e:Entity)
OPTIONAL MATCH (s)-[:ENCOUNTERED_BLOCKER]->(b:Blocker {status: 'active'})
RETURN ps, 
       collect(DISTINCT s) as RecentSessions,
       collect(DISTINCT d) as RecentDecisions,
       collect(DISTINCT e) as RecentEntities,
       collect(DISTINCT b) as ActiveBlockers
ORDER BY s.startTime DESC;
"@
}

function Get-ActiveSessionQuery {
    param(
        [string]$User = $env:USERNAME
    )
    
    @"
// Find active session
MATCH (s:Session {user: '$User', status: 'active'})
RETURN s
ORDER BY s.startTime DESC
LIMIT 1;
"@
}

# Export all functions
Export-ModuleMember -Function *-*Query
