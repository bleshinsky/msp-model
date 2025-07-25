# MSP Neo4j Setup Script
# Sets up Neo4j for MSP session tracking

param(
    [string]$Neo4jUri = "bolt://localhost:7687",
    [string]$Username = "neo4j",
    [SecureString]$Password,
    [switch]$TestConnection,
    [switch]$CreateSchema
)

Write-Host "MSP Neo4j Setup" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

# Function to display Neo4j schema creation queries
function Show-Neo4jSchema {
    $schema = @"
// MSP Neo4j Schema - Copy and run these in Neo4j Browser

// Create constraints
CREATE CONSTRAINT session_id IF NOT EXISTS FOR (s:Session) REQUIRE s.id IS UNIQUE;
CREATE CONSTRAINT project_state_name IF NOT EXISTS FOR (ps:ProjectState) REQUIRE ps.name IS UNIQUE;

// Create indexes
CREATE INDEX session_date IF NOT EXISTS FOR (s:Session) ON (s.date);
CREATE INDEX decision_date IF NOT EXISTS FOR (d:Decision) ON (d.date);
CREATE INDEX entity_name IF NOT EXISTS FOR (e:Entity) ON (e.name);

// Create initial project state
CREATE (ps:ProjectState {
    name: 'MSP Current State',
    project: 'MSP',
    progress: 0,
    phase: 'Setup',
    lastUpdated: datetime(),
    observations: ['Project initialized']
})
RETURN ps;

// Verify setup
MATCH (n) RETURN labels(n) as Label, count(n) as Count;
"@
    
    Write-Host "`nNeo4j Schema Creation Queries:" -ForegroundColor Yellow
    Write-Host $schema -ForegroundColor White
    
    # Try to copy to clipboard
    try {
        $schema | Set-Clipboard
        Write-Host "`n✅ Queries copied to clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "`n⚠️  Could not copy to clipboard. Please copy manually." -ForegroundColor Yellow
    }
}

# Test connection
if ($TestConnection) {
    Write-Host "`nTesting Neo4j connection..." -ForegroundColor Yellow
    Write-Host "Please ensure Neo4j is running at: $Neo4jUri" -ForegroundColor Gray
    
    # For browser-based approach, we just check if Neo4j Browser is accessible
    try {
        $browserUrl = $Neo4jUri -replace "bolt://", "http://" -replace ":7687", ":7474"
        Write-Host "Neo4j Browser should be available at: $browserUrl" -ForegroundColor Green
        
        # Try to open browser
        Start-Process $browserUrl -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Could not open Neo4j Browser automatically" -ForegroundColor Yellow
    }
}

# Show schema
if ($CreateSchema) {
    Show-Neo4jSchema
}

# Save configuration
$config = @{
    neo4j = @{
        uri = $Neo4jUri
        username = $Username
        browserUrl = $Neo4jUri -replace "bolt://", "http://" -replace ":7687", ":7474"
    }
}

$configPath = "..\..\config\neo4j-config.json"
$config | ConvertTo-Json -Depth 10 | Out-File $configPath -Encoding UTF8

Write-Host "`n✅ Neo4j configuration saved" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run with -CreateSchema to get schema queries" -ForegroundColor White
Write-Host "2. Copy queries to Neo4j Browser" -ForegroundColor White
Write-Host "3. Execute queries to set up MSP schema" -ForegroundColor White
