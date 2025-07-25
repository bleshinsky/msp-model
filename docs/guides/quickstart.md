# MSP Quickstart Guide

Get up and running with MSP in 5 minutes. Choose your path:

## 🚀 MSP Lite (Quickest Start)

Zero dependencies. Just PowerShell and you.

```powershell
# Download MSP Lite (single file)
iwr -Uri "https://github.com/msp-framework/msp/raw/main/lite/msp-lite.ps1" -OutFile "msp.ps1"

# Start your first session
.\msp.ps1 start

# Track your work
.\msp.ps1 update "Implemented user login" 25

# End with context captured
.\msp.ps1 end
```

That's it! Your context is saved in JSON files, ready for your next session.

## 🧠 MSP Standard (Recommended)

Full context engineering with Neo4j, Obsidian, and Linear integration.

### Prerequisites
- PowerShell 7+
- Neo4j Desktop (or Docker)
- Obsidian (optional but recommended)
- Linear account (optional)

### Quick Install

```powershell
# Clone the repository
git clone https://github.com/msp-framework/msp.git
cd msp/standard

# Run interactive setup
.\setup.ps1
```

The setup wizard will:
1. Check prerequisites
2. Configure Neo4j connection
3. Set up Obsidian vault path
4. Configure Linear integration
5. Create your first project

### Docker Alternative

If you don't have Neo4j installed:

```powershell
# Start Neo4j with Docker
cd msp/standard/docker
docker-compose up -d

# Continue with setup
cd ..
.\setup.ps1
```

## Your First Session

### 1. Start a Session

```powershell
.\msp.ps1 start

# MSP will:
# - Load any existing context
# - Show your project state
# - Generate a Neo4j query
# - Create an Obsidian daily note
```

### 2. Track Your Work

As you work, track progress in real-time:

```powershell
# Simple update
.\msp.ps1 update "Fixed authentication bug"

# Update with progress
.\msp.ps1 update "Implemented password reset" 35

# Record a decision
.\msp.ps1 decide "Using SendGrid for emails - better deliverability"

# Note a blocker
.\msp.ps1 block "API rate limits on third-party service"
```

### 3. End Your Session

```powershell
.\msp.ps1 end

# MSP will:
# - Calculate session duration
# - Generate Neo4j queries for all updates
# - Update Obsidian notes
# - Create Linear comment (if configured)
# - Archive session data
```

## Understand the Output

### Neo4j Queries
MSP generates Cypher queries but doesn't execute them automatically. Copy and run them in Neo4j Browser:

```cypher
// Example generated query
CREATE (s:Session {
    id: 'msp-2025-01-16-093042',
    startTime: datetime(),
    project: 'my-project'
})
```

### Obsidian Integration
MSP creates/updates markdown files in your vault:
- Daily notes with session summaries
- Decision records with full context
- Project overview pages

### Linear Integration
If configured, MSP formats updates for Linear:
- Session summaries as comments
- Progress updates on issues
- Decision tracking

## Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `start` | Begin a new session | `.\msp.ps1 start` |
| `update` | Track progress | `.\msp.ps1 update "message" 50` |
| `decide` | Record a decision | `.\msp.ps1 decide "chose X over Y"` |
| `block` | Note a blocker | `.\msp.ps1 block "deployment issue"` |
| `end` | End current session | `.\msp.ps1 end` |
| `status` | Check session status | `.\msp.ps1 status` |
| `context` | Export full context | `.\msp.ps1 context` |
| `recover` | Recover crashed session | `.\msp.ps1 recover` |

## Configuration

MSP uses a simple JSON configuration file:

```json
{
  "project": "my-project",
  "neo4j": {
    "uri": "bolt://localhost:7687",
    "username": "neo4j"
  },
  "obsidian": {
    "vaultPath": "C:\\Obsidian\\MyVault"
  },
  "linear": {
    "teamId": "your-team-uuid",
    "activeIssue": "PROJ-123"
  }
}
```

## Tips for Success

### 1. **Track Everything**
Even small updates matter. "Fixed typo" is progress.

### 2. **Decide Explicitly**
When you make a technical choice, record it:
```powershell
.\msp.ps1 decide "PostgreSQL over MySQL - need JSONB support"
```

### 3. **Progress Honestly**
Going backwards is progress too:
```powershell
.\msp.ps1 update "Reverted auth changes - wrong approach" 30  # was 35
```

### 4. **Context is Power**
Export context for AI assistants:
```powershell
.\msp.ps1 context | clip  # Windows
.\msp.ps1 context | pbcopy  # macOS
```

## Troubleshooting

### "No active session found"
You need to start a session first:
```powershell
.\msp.ps1 start
```

### "Neo4j connection failed"
Ensure Neo4j is running and check your config:
```powershell
.\scripts\test-neo4j.ps1
```

### "Can't find Obsidian vault"
Update your config with the correct path:
```powershell
.\msp.ps1 config obsidian.vaultPath "C:\Path\To\Vault"
```

## Next Steps

1. **Read the Concepts**
   - [Context Engineering](../concepts/context-engineering.md)
   - [The R³ Protocol](../concepts/r3-protocol.md)

2. **Explore Examples**
   - Check the `examples/` directory
   - See real workflow patterns



Welcome to context engineering. Never lose your flow again.
