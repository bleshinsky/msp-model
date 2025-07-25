# MSP Neo4j Integration

The Neo4j integration module provides graph database capabilities for the Mandatory Session Protocol (MSP), enabling sophisticated relationship tracking, state management, and analytics across development sessions.

## Features

- **Session Management**: Create, update, and close session nodes with full lifecycle tracking
- **Entity Tracking**: Capture entities, decisions, and observations in real-time
- **Progress Monitoring**: Track granular progress updates throughout sessions
- **Relationship Mapping**: Model complex relationships between sessions, entities, and decisions
- **Analytics**: Query session history, team productivity, and development patterns
- **Health Monitoring**: Built-in connection validation and integrity checks

## Installation

## Project Management

All tasks and issues are tracked in Linear:

- Project: PROJECT-NAME

- View our board: [Linear link]

### Prerequisites

- PowerShell 7.0 or higher
- Neo4j 4.4+ or 5.x (Community or Enterprise)
- .NET 6.0 Runtime (for Neo4j driver)
- Node.js 18+ (for TypeScript client)

### Quick Setup

```powershell
# Run the setup script
.\setup-neo4j.ps1 -TestConnection -CreateIndexes

# Or with custom parameters
.\setup-neo4j.ps1 `
    -Neo4jUri "bolt://your-neo4j-server:7687" `
    -Neo4jUsername "neo4j" `
    -Database "msp" `
    -TestConnection `
    -CreateIndexes
```

### Manual Installation

1. **Install Neo4j Driver**:

   ```powershell
   # Download Neo4j.Driver.dll and place in this directory
   # Or use the setup script with -SkipDriverInstall flag
   ```

2. **Set Environment Variables**:

   ```powershell
   [Environment]::SetEnvironmentVariable("NEO4J_URI", "bolt://localhost:7687", "User")
   [Environment]::SetEnvironmentVariable("NEO4J_USERNAME", "neo4j", "User")
   [Environment]::SetEnvironmentVariable("NEO4J_DATABASE", "neo4j", "User")
   ```

3. **Import Module**:

   ```powershell
   Import-Module .\MSP.Neo4j.psd1
   ```

## Usage

### PowerShell Module

```powershell
# Connect to Neo4j
Connect-Neo4j -Uri "bolt://localhost:7687" -Username "neo4j" -Password "password"

# Create a new session
$session = New-SessionNode -SessionId (New-Guid) -User $env:USERNAME

# Update progress
Update-SessionProgress -SessionId $session.id -Progress 25 -Message "Implemented core functionality"

# Add an entity
Add-EntityNode -SessionId $session.id `
    -EntityName "UserAuthService" `
    -EntityType "Service" `
    -Properties @{language = "TypeScript"; framework = "NestJS"} `
    -Observations @("Handles OAuth2 flow", "Integrates with Azure AD")

# Record a decision
Add-DecisionNode -SessionId $session.id `
    -Decision "Use Redis for session storage" `
    -Rationale "Better performance and scalability than in-memory storage" `
    -Alternatives @("In-memory storage", "PostgreSQL sessions", "JWT stateless")

# Close session
Close-SessionNode -SessionId $session.id -Summary "Completed authentication module"
```

### TypeScript Client

```typescript
import { Neo4jClient } from './neo4j-client';

// Initialize client
const client = new Neo4jClient({
  uri: 'bolt://localhost:7687',
  username: 'neo4j',
  password: 'password'
});

// Connect
await client.connect();

// Create session
const session = await client.createSession('user@example.com');

// Update progress
await client.updateSessionProgress(session.id, 50, 'Halfway complete');

// Get active sessions
const activeSessions = await client.getActiveSessions();

// Get session details
const details = await client.getSessionDetails(session.id);

// Analytics
const analytics = await client.getTeamAnalytics(
  'team-id',
  new Date('2025-01-01'),
  new Date()
);

// Subscribe to real-time updates
const unsubscribe = client.subscribeToActiveSessions(
  (sessions) => console.log('Active sessions:', sessions),
  5000 // Poll every 5 seconds
);
```

## Configuration

### config.json Structure

The configuration file defines:

- **Connection settings**: URI, credentials, retry logic
- **Schema definitions**: Node properties and validation rules
- **Relationships**: Edge types and their properties
- **Indexes**: Performance optimization
- **Constraints**: Data integrity rules

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| NEO4J_URI | Neo4j connection URI | bolt://localhost:7687 |
| NEO4J_USERNAME | Database username | neo4j |
| NEO4J_PASSWORD | Database password | (required) |
| NEO4J_DATABASE | Target database | neo4j |

## Graph Schema

### Nodes

- **Session**: Work session with progress tracking
- **Entity**: Code entities (files, classes, functions)
- **Decision**: Architectural decisions
- **Progress**: Progress snapshots
- **Observation**: Entity observations
- **Alternative**: Decision alternatives

### Relationships

- `(Session)-[:HAS_PROGRESS]->(Progress)`
- `(Session)-[:CREATED_ENTITY]->(Entity)`
- `(Session)-[:MADE_DECISION]->(Decision)`
- `(Entity)-[:HAS_OBSERVATION]->(Observation)`
- `(Decision)-[:CONSIDERED]->(Alternative)`
- `(Session)-[:LINKS_TO]->(Session)`

## Troubleshooting

### Connection Issues

```powershell
# Test connection
Test-Neo4jConnection

# Validate module setup
.\setup-neo4j.ps1 -TestConnection

# Check driver
Test-Path ".\Neo4j.Driver.dll"
```

### Common Errors

1. **"Not connected to Neo4j"**: Run `Connect-Neo4j` first
2. **"Failed to load Neo4j.Driver.dll"**: Install .NET runtime and driver
3. **"Authentication failed"**: Check credentials and database access
4. **"Transaction timeout"**: Increase timeout in config or check Neo4j performance

### Performance Tips

- Use indexes for frequently queried properties
- Batch operations when possible
- Monitor query execution with `EXPLAIN` and `PROFILE`
- Regular database maintenance with `CALL db.checkpoint()`

## Development

### Running Tests

```powershell
# PowerShell tests
Invoke-Pester .\tests\

# TypeScript tests
npm test
```

### Building TypeScript Client

```bash
npm install
npm run build
```

## Support

- GitHub Issues: [sessionprotocol/issues](https://github.com/[username]/msp/issues)
- Documentation: [sessionprotocol.dev](https://sessionprotocol.dev)
- Neo4j Resources: [neo4j.com/docs](https://neo4j.com/docs)

## License

MIT License - See LICENSE file in the root directory.
