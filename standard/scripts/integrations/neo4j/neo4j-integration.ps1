<#
.SYNOPSIS
    Neo4j setup and query generation for MSP Standard
.DESCRIPTION
    Sets up Neo4j schema and generates queries for manual execution
    Following ATAI pattern: Generate queries, don't execute directly
#>

function Initialize-Neo4jSchema {
    <#
    .SYNOPSIS
        Generates Neo4j schema creation queries
    .DESCRIPTION
        Returns Cypher queries to set up MSP schema in Neo4j
    #>
    
    $queries = @()
    
    # Constraints
    $queries += @"
// Create unique constraint for Session IDs
CREATE CONSTRAINT session_id_unique IF NOT EXISTS
FOR (s:Session) REQUIRE s.id IS UNIQUE;
"@
    
    $queries += @"
// Create unique constraint for ProjectState
CREATE CONSTRAINT project_state_name_unique IF NOT EXISTS
FOR (ps:ProjectState) REQUIRE ps.name IS UNIQUE;
"@
    
    # Indexes for performance
    $queries += @"
// Create index for session dates
CREATE INDEX session_date_index IF NOT EXISTS
FOR (s:Session) ON (s.date);
"@
    
    $queries += @"
// Create index for decision timestamps
CREATE INDEX decision_timestamp_index IF NOT EXISTS
FOR (d:Decision) ON (d.timestamp);
"@
    
    $queries += @"
// Create index for entity names
CREATE INDEX entity_name_index IF NOT EXISTS
FOR (e:Entity) ON (e.name);
"@
    
    # Initial ProjectState
    $queries += @"
// Create initial project state (customize project name)
MERGE (ps:ProjectState {name: 'My Project'})
ON CREATE SET 
    ps.progress = 0,
    ps.lastUpdated = datetime(),
    ps.phase = 'Initialization',
    ps.observations = ['Project initialized with MSP']
RETURN ps;
"@
    
    return $queries
}

function Get-Neo4jSessionQueries {
    <#
    .SYNOPSIS
        Generates queries for session management
    .PARAMETER Action
        The action to perform: start, update, end
    .PARAMETER SessionId
        The session ID
    .PARAMETER Parameters
        Additional parameters for the action
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('start', 'update', 'end')]
        [string]$Action,
        
        [string]$SessionId,
        
        [hashtable]$Parameters = @{}
    )
    
    switch ($Action) {
        'start' {
            return @"
// Create new session
CREATE (s:Session {
    id: '$SessionId',
    startTime: datetime(),
    date: date(),
    user: '$($env:USERNAME)',
    project: '$(if($Parameters.project) {$Parameters.project} else {'My Project'})',
    status: 'active',
    progress: $(if($Parameters.progress) {$Parameters.progress} else {0})
})
RETURN s;
"@
        }
        
        'update' {
            $queries = @()
            
            # Create progress node
            $queries += @"
// Create progress update
MATCH (s:Session {id: '$SessionId', status: 'active'})
CREATE (p:Progress {
    timestamp: datetime(),
    percentage: $(if($Parameters.progress -ge 0) {$Parameters.progress} else {'s.progress'}),
    message: '$($Parameters.message -replace "'", "''")'
})
CREATE (s)-[:HAS_PROGRESS]->(p)
SET s.lastUpdate = datetime()
$(if($Parameters.progress -ge 0) {"SET s.progress = $($Parameters.progress)"})
RETURN s, p;
"@
            
            # Check for decision keywords
            if ($Parameters.message -match '\b(decided?|chose|selected|going with)\b') {
                $queries += @"
// Auto-create decision from update
MATCH (s:Session {id: '$SessionId', status: 'active'})
CREATE (d:Decision {
    content: '$($Parameters.message -replace "'", "''")',
    timestamp: datetime(),
    sessionId: '$SessionId'
})
CREATE (s)-[:MADE_DECISION]->(d)
RETURN d;
"@
            }
            
            return $queries -join "`n`n"
        }
        
        'end' {
            return @"
// End session and update project state
MATCH (s:Session {id: '$SessionId', status: 'active'})
SET s.endTime = datetime(),
    s.status = 'completed',
    s.duration = duration.between(s.startTime, datetime()).hours + 
                 duration.between(s.startTime, datetime()).minutes / 60.0

WITH s
MATCH (ps:ProjectState {name: s.project})
SET ps.lastUpdated = datetime(),
    ps.progress = s.progress

RETURN s, ps;
"@
        }
    }
}

function Show-Neo4jSetup {
    <#
    .SYNOPSIS
        Shows Neo4j setup instructions
    #>
    
    Write-Host "`n🔗 Neo4j Setup Instructions" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    
    Write-Host "`n1. Install Neo4j Desktop:" -ForegroundColor Yellow
    Write-Host "   Download from: https://neo4j.com/download/" -ForegroundColor White
    Write-Host "   Or use Docker: docker run -p 7474:7474 -p 7687:7687 neo4j" -ForegroundColor White
    
    Write-Host "`n2. Create Database:" -ForegroundColor Yellow
    Write-Host "   - Open Neo4j Desktop" -ForegroundColor White
    Write-Host "   - Create new project" -ForegroundColor White
    Write-Host "   - Add local DBMS (use password you'll remember)" -ForegroundColor White
    Write-Host "   - Start the database" -ForegroundColor White
    
    Write-Host "`n3. Initialize Schema:" -ForegroundColor Yellow
    Write-Host "   Run: .\msp.ps1 neo4j init" -ForegroundColor White
    Write-Host "   Copy the generated queries to Neo4j Browser" -ForegroundColor White
    
    Write-Host "`n4. Configure MSP:" -ForegroundColor Yellow
    Write-Host "   .\msp.ps1 config neo4j.boltUri bolt://localhost:7687" -ForegroundColor White
    Write-Host "   .\msp.ps1 config neo4j.database neo4j" -ForegroundColor White
    
    Write-Host "`n5. Usage:" -ForegroundColor Yellow
    Write-Host "   MSP generates queries for you to run in Neo4j Browser" -ForegroundColor White
    Write-Host "   Or ask Claude to execute them using Neo4j MCP tools" -ForegroundColor White
    
    Write-Host ""
}

function Test-Neo4jConnection {
    <#
    .SYNOPSIS
        Generates a test query for Neo4j
    #>
    
    Write-Host "`n🔍 Neo4j Connection Test" -ForegroundColor Cyan
    Write-Host "Copy this query to Neo4j Browser:" -ForegroundColor Yellow
    Write-Host ""
    
    $testQuery = @"
// MSP Connection Test
RETURN 'MSP Neo4j Integration Ready!' AS message, 
       datetime() AS timestamp,
       version() AS neo4jVersion;
"@
    
    Write-Host $testQuery -ForegroundColor White
    
    # Try to copy to clipboard
    try {
        $testQuery | Set-Clipboard
        Write-Host "`n✅ Query copied to clipboard!" -ForegroundColor Green
    } catch {
        # Clipboard not available
    }
    
    Write-Host "`nIf you see results, Neo4j is working correctly!" -ForegroundColor Green
}

function Get-Neo4jAnalyticsQueries {
    <#
    .SYNOPSIS
        Generates useful analytics queries
    #>
    
    return @{
        TodaysSessions = @"
// Today's sessions
MATCH (s:Session)
WHERE s.date = date()
RETURN s.id, s.startTime, s.endTime, s.progress, s.status
ORDER BY s.startTime DESC;
"@
        
        RecentDecisions = @"
// Recent decisions (last 7 days)
MATCH (d:Decision)
WHERE d.timestamp > datetime() - duration('P7D')
RETURN d.content, d.timestamp
ORDER BY d.timestamp DESC
LIMIT 10;
"@
        
        ProgressOverTime = @"
// Progress over time
MATCH (s:Session)
WHERE s.status = 'completed'
RETURN s.date, MAX(s.progress) as progress
ORDER BY s.date;
"@
        
        ActiveBlockers = @"
// Active blockers
MATCH (b:Blocker)
WHERE b.status = 'active'
RETURN b.description, b.createdAt
ORDER BY b.createdAt DESC;
"@
        
        SessionStats = @"
// Session statistics
MATCH (s:Session)
WHERE s.status = 'completed'
RETURN 
    COUNT(s) as totalSessions,
    AVG(s.duration) as avgDuration,
    SUM(s.duration) as totalHours,
    MAX(s.progress) as maxProgress;
"@
    }
}

# Export functions
Export-ModuleMember -Function Initialize-Neo4jSchema, Get-Neo4jSessionQueries, Show-Neo4jSetup, Test-Neo4jConnection, Get-Neo4jAnalyticsQueries
