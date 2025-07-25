# MSP Neo4j Integration (Browser-Based)

This integration uses Neo4j Browser for all operations.

## How It Works

MSP generates Cypher queries that you copy and run in Neo4j Browser. This approach:
- Requires no drivers or complex setup
- Works with your existing Neo4j Desktop installation
- Provides full visibility into what's being stored
- Allows manual adjustments when needed

## Quick Start

1. **Ensure Neo4j is running** in Neo4j Desktop
2. **Test the connection**:
   ```powershell
   .\test-neo4j-browser.ps1
   ```

3. **Start using MSP**:
   ```powershell
   # From the project root
   .\msp.ps1 start
   # Copy the generated query and run in Neo4j Browser
   
   .\msp.ps1 update "Implemented feature X" 25
   # Copy and run the update query
   
   .\msp.ps1 end
   # Copy and run the session end query
   ```

## What Gets Tracked

### Session Nodes
- Start/end times
- Progress percentage
- User and project info
- Session summary

### Progress Nodes
- Timestamp of each update
- Progress percentage
- Update message

### Decision Nodes
- Automatically created when your notes contain decision keywords
- Linked to the session

### Entity Nodes
- Created when you mention building/implementing something
- Tracks what was created during the session

### Blocker Nodes
- Tracked when you mention issues or problems
- Helps identify patterns

## Neo4j Schema

```cypher
// Core nodes
(:Session {id, name, user, project, startTime, endTime, status, progress})
(:Progress {timestamp, percentage, message})
(:Decision {content, timestamp, sessionId})
(:Entity {name, type, createdAt, sessionId})
(:Blocker {description, status, createdAt, sessionId})
(:ProjectState {name, progress, observations, lastUpdate})

// Relationships
(Session)-[:HAS_PROGRESS]->(Progress)
(Session)-[:MADE_DECISION]->(Decision)
(Session)-[:CREATED_ENTITY]->(Entity)
(Session)-[:ENCOUNTERED_BLOCKER]->(Blocker)
```

## Useful Neo4j Queries

```cypher
// Get current project state
MATCH (ps:ProjectState {name: 'PROJECT-NAME Current State'})
RETURN ps

// View today's session
MATCH (s:Session)
WHERE s.date = date()
RETURN s

// See all progress updates
MATCH (s:Session)-[:HAS_PROGRESS]->(p:Progress)
WHERE s.user = 'YOUR_USERNAME'
RETURN s.date, p.timestamp, p.message, p.percentage
ORDER BY p.timestamp DESC

// Find all decisions
MATCH (s:Session)-[:MADE_DECISION]->(d:Decision)
RETURN s.date, d.content
ORDER BY d.timestamp DESC

// Check active blockers
MATCH (b:Blocker {status: 'active'})
RETURN b

// Session summary
MATCH (s:Session)
WHERE s.status = 'completed'
RETURN s.date, s.duration, s.progress
ORDER BY s.date DESC
LIMIT 10
```

## Integration with Main MSP

The main `msp.ps1` script automatically:
1. Opens Neo4j Browser when starting a session
2. Generates appropriate Cypher queries
3. Copies queries to clipboard (when possible)
4. Updates Obsidian notes
5. Tracks state locally

## Troubleshooting

**Neo4j Browser won't open**
- Check if Neo4j is running in Neo4j Desktop
- Try accessing http://localhost:7474 directly

**Queries won't copy to clipboard**
- Run PowerShell as Administrator
- Or manually copy the displayed queries

**Session already active error**
- Run `.\msp.ps1 end` to close the previous session
- Or manually update the session in Neo4j

## Next Steps

1. Run a test session to verify everything works
2. Customize the queries if needed
3. Set up any additional indexes for performance
4. Create views in Neo4j Browser for quick access
