# EXAMPLE SETUP FILE - CREATE THE STRUCTURE THAT FITS YOUR PROJECT
# PROJECT-NAME Neo4j Schema Setup
Write-Host "Setting up Neo4j schema for PROJECT-NAME..." -ForegroundColor Cyan
Write-Host ""

Write-Host "STEP 1: Create all nodes" -ForegroundColor Yellow
$createNodes = @'
// Create PROJECT-NAME project state
CREATE (ps:ProjectState {
    name: 'PROJECT-NAME Current State',
    project: 'Mandatory Session Protocol',
    domain: 'example.com',
    startDate: 'XXXX-XX-XX',
    targetLaunch: 'XXXXXX',
    progress: 0,
    observations: [
        'EXAMPLE Project initialized',
        'EXAMPLE Repository structure created',
        'EXAMPLE PowerShell automation implemented'
    ]
})

// Create initial technical artifacts
CREATE (ta1:TechnicalArtifact {
    name: 'msp.ps1',
    type: 'script',
    purpose: 'Main CLI entry point',
    status: 'created'
})

CREATE (ta2:TechnicalArtifact {
    name: 'msp-automation.ps1', 
    type: 'script',
    purpose: 'Core session management logic',
    status: 'created'
})

CREATE (ta3:TechnicalArtifact {
    name: 'msp-validate.ps1',
    type: 'script', 
    purpose: 'System validation and health checks',
    status: 'created'
})

// Create project milestones
CREATE (m1:Milestone {
    name: 'Architecture Complete',
    targetDate: 'XXXX-XX-XX',
    progress: 10
})

CREATE (m2:Milestone {
    name: 'Core CLI Functional',
    targetDate: 'XXXX-XX-XX', 
    progress: 30
})

CREATE (m3:Milestone {
    name: 'Integrations Complete',
    targetDate: 'XXXX-XX-XX',
    progress: 50
})

CREATE (m4:Milestone {
    name: 'Web Dashboard MVP',
    targetDate: 'XXXX-XX-XX',
    progress: 70
})

CREATE (m5:Milestone {
    name: 'Public Launch',
    targetDate: 'XXXX-XX-XX',
    progress: 100
})

// Create initial epics
CREATE (e1:Epic {
    name: 'User Research & Validation',
    linearId: 'PROJECT-NAME-1',
    status: 'backlog',
    points: 20
})

CREATE (e2:Epic {
    name: 'Technical Architecture', 
    linearId: 'PROJECT-NAME-2',
    status: 'backlog',
    points: 30
})

CREATE (e3:Epic {
    name: 'Core Feature Development',
    linearId: 'PROJECT-NAME-3', 
    status: 'backlog',
    points: 50
})

CREATE (e4:Epic {
    name: 'Frontend Implementation',
    linearId: 'PROJECT-NAME-4',
    status: 'backlog', 
    points: 40
})

CREATE (e5:Epic {
    name: 'Integration & Testing',
    linearId: 'PROJECT-NAME-5',
    status: 'backlog',
    points: 25
})

CREATE (e6:Epic {
    name: 'Launch Preparation',
    linearId: 'PROJECT-NAME-6',
    status: 'backlog',
    points: 15
})

RETURN 'Nodes created successfully!' AS result
'@

Write-Host $createNodes -ForegroundColor White
Write-Host ""
Write-Host "STEP 2: Create relationships" -ForegroundColor Yellow

$createRelationships = @'
// Link milestones to project
MATCH (ps:ProjectState {name: 'PROJECT-NAME Current State'})
MATCH (m:Milestone)
CREATE (ps)-[:HAS_MILESTONE]->(m);

// Link artifacts to project
MATCH (ps:ProjectState {name: 'PROJECT-NAME Current State'})
MATCH (ta:TechnicalArtifact)
CREATE (ps)-[:INCLUDES]->(ta);

// Link epics to project
MATCH (ps:ProjectState {name: 'PROJECT-NAME Current State'})
MATCH (e:Epic)
CREATE (ps)-[:PLANNED_WORK]->(e);

// Return summary
MATCH (ps:ProjectState {name: 'PROJECT-NAME Current State'})
MATCH (ps)-[r]->(connected)
RETURN ps.name AS Project, type(r) AS Relationship, labels(connected)[0] AS ConnectedType, count(connected) AS Count
ORDER BY ConnectedType
'@

Write-Host $createRelationships -ForegroundColor White
Write-Host ""
Write-Host "STEP 3: Verify creation" -ForegroundColor Yellow

$verifyCreation = @'
// Count all nodes by type
MATCH (n)
RETURN labels(n)[0] as NodeType, count(n) as Count
ORDER BY Count DESC
'@

Write-Host $verifyCreation -ForegroundColor White
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Green
Write-Host "1. Open Neo4j Browser at http://localhost:7474" -ForegroundColor Cyan
Write-Host "2. Run each query above separately in order" -ForegroundColor Cyan
Write-Host "3. Verify each step completes successfully" -ForegroundColor Cyan
