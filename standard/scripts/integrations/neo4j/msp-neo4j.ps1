# msp-neo4j.ps1
# Simple Neo4j integration for MSP - using browser-based approach

[CmdletBinding()]
param(
    [string]$Command,
    [hashtable]$Parameters = @{}
)

# Neo4j connection settings (matches your Neo4j Desktop setup)
$script:Neo4jBrowser = "http://localhost:7474"
$script:Neo4jBolt = "bolt://localhost:7687"

function Open-Neo4jBrowser {
    Write-Host "Opening Neo4j Browser..." -ForegroundColor Cyan
    Start-Process $script:Neo4jBrowser
}

function Get-SessionQueries {
    @{
        CreateSession = @"
CREATE (s:Session {
    id: randomUUID(),
    user: '$env:USERNAME',
    project: 'MSP',
    startTime: datetime(),
    status: 'active',
    progress: 0
})
RETURN s
"@

        UpdateProgress = @"
MATCH (s:Session {status: 'active'})
WHERE s.user = '$env:USERNAME'
ORDER BY s.startTime DESC
LIMIT 1
SET s.progress = {progress},
    s.lastUpdate = datetime()
CREATE (p:Progress {
    timestamp: datetime(),
    percentage: {progress},
    message: '{message}'
})
CREATE (s)-[:HAS_PROGRESS]->(p)
RETURN s, p
"@

        EndSession = @"
MATCH (s:Session {status: 'active'})
WHERE s.user = '$env:USERNAME'
ORDER BY s.startTime DESC
LIMIT 1
SET s.status = 'completed',
    s.endTime = datetime(),
    s.summary = '{summary}'
RETURN s
"@

        GetCurrentState = @"
MATCH (s:Session)
WHERE s.user = '$env:USERNAME'
ORDER BY s.startTime DESC
LIMIT 1
OPTIONAL MATCH (s)-[:HAS_PROGRESS]->(p:Progress)
RETURN s, collect(p) as progress
ORDER BY p.timestamp DESC
"@

        AddEntity = @"
MATCH (s:Session {status: 'active'})
WHERE s.user = '$env:USERNAME'
ORDER BY s.startTime DESC
LIMIT 1
CREATE (e:Entity {
    name: '{name}',
    type: '{type}',
    createdAt: datetime()
})
CREATE (s)-[:CREATED_ENTITY]->(e)
RETURN e
"@

        AddDecision = @"
MATCH (s:Session {status: 'active'})
WHERE s.user = '$env:USERNAME'
ORDER BY s.startTime DESC
LIMIT 1
CREATE (d:Decision {
    content: '{decision}',
    rationale: '{rationale}',
    timestamp: datetime()
})
CREATE (s)-[:MADE_DECISION]->(d)
RETURN d
"@
    }
}

function Show-CypherQuery {
    param(
        [string]$QueryName,
        [hashtable]$Values = @{}
    )
    
    $queries = Get-SessionQueries
    $query = $queries[$QueryName]
    
    # Replace placeholders
    foreach ($key in $Values.Keys) {
        $query = $query -replace "{$key}", $Values[$key]
    }
    
    Write-Host "`nCypher Query for Neo4j Browser:" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host $query -ForegroundColor Yellow
    Write-Host "`nCopy and paste this into Neo4j Browser" -ForegroundColor Green
    
    # Copy to clipboard if possible
    try {
        $query | Set-Clipboard
        Write-Host "Query copied to clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "Could not copy to clipboard - please copy manually" -ForegroundColor Gray
    }
}

# Main command processing
switch ($Command) {
    "start" {
        Open-Neo4jBrowser
        Show-CypherQuery -QueryName "CreateSession"
    }
    
    "update" {
        if ($Parameters.Progress -and $Parameters.Message) {
            Show-CypherQuery -QueryName "UpdateProgress" -Values @{
                progress = $Parameters.Progress
                message = $Parameters.Message
            }
        } else {
            Write-Host "Usage: .\msp-neo4j.ps1 update @{Progress=25; Message='Completed task'}" -ForegroundColor Red
        }
    }
    
    "end" {
        $summary = $Parameters.Summary ?? "Session completed"
        Show-CypherQuery -QueryName "EndSession" -Values @{
            summary = $summary
        }
    }
    
    "status" {
        Open-Neo4jBrowser
        Show-CypherQuery -QueryName "GetCurrentState"
    }
    
    "entity" {
        if ($Parameters.Name -and $Parameters.Type) {
            Show-CypherQuery -QueryName "AddEntity" -Values @{
                name = $Parameters.Name
                type = $Parameters.Type
            }
        } else {
            Write-Host "Usage: .\msp-neo4j.ps1 entity @{Name='ComponentName'; Type='Service'}" -ForegroundColor Red
        }
    }
    
    "decision" {
        if ($Parameters.Decision) {
            Show-CypherQuery -QueryName "AddDecision" -Values @{
                decision = $Parameters.Decision
                rationale = $Parameters.Rationale ?? ""
            }
        } else {
            Write-Host "Usage: .\msp-neo4j.ps1 decision @{Decision='Use Redis'; Rationale='Better performance'}" -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "MSP Neo4j Integration" -ForegroundColor Cyan
        Write-Host "=====================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  start    - Create a new session" -ForegroundColor White
        Write-Host "  update   - Update progress" -ForegroundColor White
        Write-Host "  end      - End current session" -ForegroundColor White
        Write-Host "  status   - Check current state" -ForegroundColor White
        Write-Host "  entity   - Add an entity" -ForegroundColor White
        Write-Host "  decision - Record a decision" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host '  .\msp-neo4j.ps1 start' -ForegroundColor Gray
        Write-Host '  .\msp-neo4j.ps1 update @{Progress=25; Message="Implemented auth"}' -ForegroundColor Gray
        Write-Host '  .\msp-neo4j.ps1 entity @{Name="UserService"; Type="Component"}' -ForegroundColor Gray
        Write-Host '  .\msp-neo4j.ps1 decision @{Decision="Use JWT"; Rationale="Stateless auth"}' -ForegroundColor Gray
        Write-Host '  .\msp-neo4j.ps1 end @{Summary="Completed MVP setup"}' -ForegroundColor Gray
    }
}
