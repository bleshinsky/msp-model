# neo4j-connection.ps1
# MSP Neo4j Connection Module
# Handles all Neo4j database operations for session tracking

using namespace System.Collections.Generic

# Module configuration
$script:Neo4jConfig = @{
    Uri = $env:NEO4J_URI ?? "bolt://localhost:7687"
    Username = $env:NEO4J_USERNAME ?? "neo4j"
    Password = $env:NEO4J_PASSWORD ?? "password"
    Database = $env:NEO4J_DATABASE ?? "neo4j"
    MaxRetries = 3
    RetryDelay = 1000
}

# Connection state
$script:Neo4jDriver = $null
$script:IsConnected = $false

function Connect-Neo4j {
    [CmdletBinding()]
    param(
        [string]$Uri = $script:Neo4jConfig.Uri,
        [string]$Username = $script:Neo4jConfig.Username,
        [string]$Password = $script:Neo4jConfig.Password,
        [string]$Database = $script:Neo4jConfig.Database
    )

    try {
        Write-Verbose "Connecting to Neo4j at $Uri"
        
        # Import Neo4j driver (assumes Neo4j.Driver package is installed)
        Add-Type -Path "$PSScriptRoot\Neo4j.Driver.dll" -ErrorAction Stop
        
        $authToken = [Neo4j.Driver.AuthTokens]::Basic($Username, $Password)
        $script:Neo4jDriver = [Neo4j.Driver.GraphDatabase]::Driver($Uri, $authToken)
        
        # Test connection
        $session = $script:Neo4jDriver.AsyncSession()
        $result = $session.RunAsync("RETURN 1 AS test").Result
        $session.CloseAsync().Wait()
        
        $script:IsConnected = $true
        Write-Verbose "Successfully connected to Neo4j"
        return $true
    }
    catch {
        Write-Error "Failed to connect to Neo4j: $_"
        $script:IsConnected = $false
        return $false
    }
}

function Disconnect-Neo4j {
    [CmdletBinding()]
    param()
    
    if ($script:Neo4jDriver) {
        $script:Neo4jDriver.CloseAsync().Wait()
        $script:Neo4jDriver = $null
        $script:IsConnected = $false
        Write-Verbose "Disconnected from Neo4j"
    }
}

function Test-Neo4jConnection {
    [CmdletBinding()]
    param()
    
    if (-not $script:IsConnected -or -not $script:Neo4jDriver) {
        return $false
    }
    
    try {
        $session = $script:Neo4jDriver.AsyncSession()
        $result = $session.RunAsync("RETURN 1 AS test").Result
        $session.CloseAsync().Wait()
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-Neo4jQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        
        [hashtable]$Parameters = @{},
        
        [switch]$ReadOnly
    )
    
    if (-not $script:IsConnected) {
        throw "Not connected to Neo4j. Call Connect-Neo4j first."
    }
    
    $retryCount = 0
    $maxRetries = $script:Neo4jConfig.MaxRetries
    
    while ($retryCount -lt $maxRetries) {
        try {
            $sessionConfig = [Neo4j.Driver.SessionConfig]::Builder
            if ($ReadOnly) {
                $sessionConfig = $sessionConfig.WithDefaultAccessMode([Neo4j.Driver.AccessMode]::Read)
            }
            
            $session = $script:Neo4jDriver.AsyncSession($sessionConfig.Build())
            
            try {
                $result = if ($Parameters.Count -gt 0) {
                    $session.RunAsync($Query, $Parameters).Result
                } else {
                    $session.RunAsync($Query).Result
                }
                
                $records = [List[object]]::new()
                while ($result.FetchAsync().Result) {
                    $records.Add($result.Current)
                }
                
                return $records
            }
            finally {
                $session.CloseAsync().Wait()
            }
        }
        catch {
            $retryCount++
            if ($retryCount -ge $maxRetries) {
                throw "Neo4j query failed after $maxRetries attempts: $_"
            }
            Write-Warning "Neo4j query failed, retrying ($retryCount/$maxRetries)..."
            Start-Sleep -Milliseconds $script:Neo4jConfig.RetryDelay
        }
    }
}

# Session Management Functions
function New-SessionNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [string]$User = $env:USERNAME,
        
        [hashtable]$Properties = @{}
    )
    
    $query = @"
CREATE (s:Session {
    id: `$sessionId,
    user: `$user,
    startTime: datetime(),
    status: 'active',
    progress: 0
})
SET s += `$properties
RETURN s
"@
    
    $params = @{
        sessionId = $SessionId
        user = $User
        properties = $Properties
    }
    
    $result = Invoke-Neo4jQuery -Query $query -Parameters $params
    return $result[0]
}

function Update-SessionProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [Parameter(Mandatory)]
        [int]$Progress,
        
        [string]$Message = ""
    )
    
    $query = @"
MATCH (s:Session {id: `$sessionId, status: 'active'})
SET s.progress = `$progress,
    s.lastUpdate = datetime()
CREATE (p:Progress {
    timestamp: datetime(),
    percentage: `$progress,
    message: `$message
})
CREATE (s)-[:HAS_PROGRESS]->(p)
RETURN s, p
"@
    
    $params = @{
        sessionId = $SessionId
        progress = $Progress
        message = $Message
    }
    
    return Invoke-Neo4jQuery -Query $query -Parameters $params
}

function Add-EntityNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [Parameter(Mandatory)]
        [string]$EntityName,
        
        [Parameter(Mandatory)]
        [string]$EntityType,
        
        [hashtable]$Properties = @{},
        
        [string[]]$Observations = @()
    )
    
    $query = @"
MATCH (s:Session {id: `$sessionId, status: 'active'})
CREATE (e:Entity {
    name: `$entityName,
    type: `$entityType,
    createdAt: datetime()
})
SET e += `$properties
CREATE (s)-[:CREATED_ENTITY]->(e)
WITH e
UNWIND `$observations AS observation
CREATE (o:Observation {
    content: observation,
    timestamp: datetime()
})
CREATE (e)-[:HAS_OBSERVATION]->(o)
RETURN e
"@
    
    $params = @{
        sessionId = $SessionId
        entityName = $EntityName
        entityType = $EntityType
        properties = $Properties
        observations = $Observations
    }
    
    return Invoke-Neo4jQuery -Query $query -Parameters $params
}

function Add-DecisionNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [Parameter(Mandatory)]
        [string]$Decision,
        
        [string]$Rationale = "",
        
        [string[]]$Alternatives = @()
    )
    
    $query = @"
MATCH (s:Session {id: `$sessionId, status: 'active'})
CREATE (d:Decision {
    content: `$decision,
    rationale: `$rationale,
    timestamp: datetime()
})
CREATE (s)-[:MADE_DECISION]->(d)
WITH d
UNWIND `$alternatives AS alternative
CREATE (a:Alternative {content: alternative})
CREATE (d)-[:CONSIDERED]->(a)
RETURN d
"@
    
    $params = @{
        sessionId = $SessionId
        decision = $Decision
        rationale = $Rationale
        alternatives = $Alternatives
    }
    
    return Invoke-Neo4jQuery -Query $query -Parameters $params
}

function Get-ActiveSession {
    [CmdletBinding()]
    param(
        [string]$User = $env:USERNAME
    )
    
    $query = @"
MATCH (s:Session {user: `$user, status: 'active'})
RETURN s
ORDER BY s.startTime DESC
LIMIT 1
"@
    
    $params = @{ user = $User }
    $result = Invoke-Neo4jQuery -Query $query -Parameters $params -ReadOnly
    
    if ($result.Count -gt 0) {
        return $result[0].Values["s"]
    }
    return $null
}

function Close-SessionNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId,
        
        [string]$Summary = ""
    )
    
    $query = @"
MATCH (s:Session {id: `$sessionId, status: 'active'})
SET s.status = 'completed',
    s.endTime = datetime(),
    s.summary = `$summary
RETURN s
"@
    
    $params = @{
        sessionId = $SessionId
        summary = $Summary
    }
    
    return Invoke-Neo4jQuery -Query $query -Parameters $params
}

function Get-SessionHistory {
    [CmdletBinding()]
    param(
        [string]$User = $env:USERNAME,
        
        [int]$Limit = 10,
        
        [datetime]$Since
    )
    
    $query = @"
MATCH (s:Session {user: `$user})
WHERE s.startTime >= `$since
OPTIONAL MATCH (s)-[:HAS_PROGRESS]->(p:Progress)
OPTIONAL MATCH (s)-[:CREATED_ENTITY]->(e:Entity)
OPTIONAL MATCH (s)-[:MADE_DECISION]->(d:Decision)
RETURN s, 
       count(DISTINCT p) AS progressCount,
       count(DISTINCT e) AS entityCount,
       count(DISTINCT d) AS decisionCount
ORDER BY s.startTime DESC
LIMIT `$limit
"@
    
    $params = @{
        user = $User
        limit = $Limit
        since = $Since ?? [datetime]::MinValue
    }
    
    return Invoke-Neo4jQuery -Query $query -Parameters $params -ReadOnly
}

# Validation Functions
function Test-SessionIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SessionId
    )
    
    $query = @"
MATCH (s:Session {id: `$sessionId})
OPTIONAL MATCH (s)-[:HAS_PROGRESS]->(p:Progress)
OPTIONAL MATCH (s)-[:CREATED_ENTITY]->(e:Entity)
OPTIONAL MATCH (s)-[:MADE_DECISION]->(d:Decision)
WITH s, 
     collect(DISTINCT p) AS progress,
     collect(DISTINCT e) AS entities,
     collect(DISTINCT d) AS decisions
RETURN s,
       size(progress) AS progressCount,
       size(entities) AS entityCount,
       size(decisions) AS decisionCount,
       CASE 
           WHEN s.status = 'active' AND NOT exists(s.endTime) THEN true
           WHEN s.status = 'completed' AND exists(s.endTime) THEN true
           ELSE false
       END AS isValid
"@
    
    $params = @{ sessionId = $SessionId }
    return Invoke-Neo4jQuery -Query $query -Parameters $params -ReadOnly
}

# Export module functions
Export-ModuleMember -Function @(
    'Connect-Neo4j',
    'Disconnect-Neo4j',
    'Test-Neo4jConnection',
    'Invoke-Neo4jQuery',
    'New-SessionNode',
    'Update-SessionProgress',
    'Add-EntityNode',
    'Add-DecisionNode',
    'Get-ActiveSession',
    'Close-SessionNode',
    'Get-SessionHistory',
    'Test-SessionIntegrity'
)
