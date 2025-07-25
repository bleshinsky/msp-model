# MSP Standard - The NOL Framework

Full-featured MSP implementation with Neo4j knowledge graph, Obsidian documentation, and Linear issue tracking.

## 🚀 Quick Setup (45 minutes)

### Prerequisites
- PowerShell 7+ 
- Docker Desktop (for Neo4j) or Neo4j Desktop
- Obsidian (optional but recommended)
- Linear account (optional)

### Automated Setup
```powershell
# Clone the repository
git clone https://github.com/yourusername/msp.git
cd msp/standard

# Run interactive setup
.\setup.ps1
```

The setup wizard will:
1. Check prerequisites
2. Configure Neo4j connection
3. Set up Obsidian vault path
4. Configure Linear integration
5. Create initial configuration
6. Test all connections

### Manual Setup
If you prefer manual configuration:

1. **Neo4j Setup**
   ```powershell
   # Option 1: Docker (recommended)
   cd docker
   docker-compose up -d
   
   # Option 2: Neo4j Desktop
   # Download from https://neo4j.com/download/
   # Create new project with password
   ```

2. **Configuration**
   ```powershell
   # Copy example config
   Copy-Item config\msp-config.example.json config\msp-config.json
   
   # Edit configuration
   notepad config\msp-config.json
   ```

3. **Test Setup**
   ```powershell
   .\msp.ps1 config test
   ```

## 📖 The NOL Framework

NOL = Neo4j + Obsidian + Linear

### Neo4j - Knowledge Graph
- Tracks relationships between sessions, decisions, and entities
- Enables complex queries about your project history
- Provides visual graph exploration

### Obsidian - Documentation
- Automatic daily notes for each session
- Markdown-based documentation
- Cross-linked knowledge base
- Templates for consistent structure

### Linear - Project Management
- Syncs with your Linear issues
- Adds session comments automatically
- Tracks progress on epics and tasks

## 🎯 Core Usage

### The R³ Protocol

```powershell
# ROUTE - Set your destination
.\msp.ps1 start
.\msp.ps1 route "Build authentication system"

# RECALL - Previous context loads automatically
# (MSP shows recent sessions, decisions, blockers)

# RECORD - Track everything
.\msp.ps1 update "Created User model" 10
.\msp.ps1 update "Decided to use JWT for stateless auth"
.\msp.ps1 update "Implemented login endpoint" 25

# Complete the loop
.\msp.ps1 end
```

### Integration Modes

MSP Standard supports three modes:

1. **Cypher Mode** - Generates queries for you to run
   ```powershell
   .\msp.ps1 config features.integrationMode cypher
   ```

2. **MCP Mode** - For use with Claude's MCP tools
   ```powershell
   .\msp.ps1 config features.integrationMode mcp
   ```

3. **Integrated Mode** - Full automation (requires setup)
   ```powershell
   .\msp.ps1 config features.integrationMode integrated
   ```

## 🔧 Configuration

### Key Configuration Options

```json
{
  "neo4j": {
    "uri": "bolt://localhost:7687",
    "username": "neo4j",
    "database": "neo4j"
  },
  "obsidian": {
    "vaultPath": "C:\\Obsidian\\MyVault",
    "dailyNotesPath": "Daily Notes",
    "templatesPath": "Templates"
  },
  "linear": {
    "teamId": "your-team-id",
    "projectId": "your-project-id"
  },
  "features": {
    "integrationMode": "integrated",
    "autoValidate": true,
    "sessionTimeout": 24
  }
}
```

### Environment Variables

You can override config with environment variables:

```powershell
$env:MSP_NEO4J_URI = "bolt://your-server:7687"
$env:MSP_OBSIDIAN_VAULT = "D:\\Documents\\Obsidian"
$env:MSP_LINEAR_TEAM = "your-team-id"
```

## 📊 Neo4j Queries

Useful queries for exploring your knowledge graph:

```cypher
// View recent sessions
MATCH (s:Session) 
WHERE s.date > date() - duration('P7D')
RETURN s ORDER BY s.startTime DESC

// Find all decisions
MATCH (d:Decision)
RETURN d.content, d.rationale, d.timestamp
ORDER BY d.timestamp DESC

// Track progress over time
MATCH (s:Session)
RETURN s.date, s.progress, s.duration
ORDER BY s.date
```

## 📝 Obsidian Integration

MSP creates structured notes:

```
Daily Notes/
├── 2025-01-16.md      # Today's session
├── 2025-01-15.md      # Yesterday's work
└── ...

Projects/MSP/
├── Decisions/         # Architectural decisions
├── Sessions/          # Detailed session logs
└── README.md          # Project overview
```

### Templates

Customize your templates in `Templates/`:
- `Session Template.md`
- `Decision Template.md`
- `Daily Note Template.md`

## 📋 Linear Integration

### Using with Claude MCP

```powershell
# Check Linear configuration
.\msp.ps1 linear

# Then ask Claude:
"Update my Linear issue NOA-234 with today's MSP progress"
```

### Direct Integration

When in integrated mode, MSP automatically:
- Comments on active issues with session summaries
- Updates progress percentages
- Links decisions to issues

## 🚨 Troubleshooting

### Neo4j Connection Issues
```powershell
# Test connection
.\msp.ps1 neo4j test

# Check Docker
docker ps

# Verify credentials
.\msp.ps1 config show
```

### Obsidian Sync Problems
```powershell
# Verify vault path
Test-Path (Get-MSPConfig).obsidian.vaultPath

# Check permissions
.\msp.ps1 validate
```

### Session Recovery
```powershell
# List all sessions
.\msp.ps1 sessions

# Recover crashed session
.\msp.ps1 recover

# Force end stuck session
.\msp.ps1 recover -Force
```

## 🎓 Advanced Features

### Custom Workflows
Create custom commands in `scripts/custom/`:

```powershell
# Example: Daily standup generator
.\msp.ps1 standup
```

### Export Formats
```powershell
# AI-ready context
.\msp.ps1 context ai | clip

# JSON for processing
.\msp.ps1 context json > context.json

# Markdown report
.\msp.ps1 context md > report.md
```

### Batch Operations
```powershell
# Process multiple updates
@("Task 1", "Task 2", "Task 3") | ForEach-Object {
    .\msp.ps1 update $_
}
```

## 📚 Best Practices

1. **Always start and end sessions** - This maintains context integrity
2. **Use descriptive updates** - "Implemented OAuth2" vs "Did auth stuff"
3. **Track decisions immediately** - Use keywords like "decided", "chose"
4. **Set routes for clarity** - Define session goals upfront
5. **Regular validation** - Run `.\msp.ps1 validate` weekly

## 🤝 Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](../../LICENSE) for details.

---

**MSP Standard**: Never lose context again. Full NOL Framework power. 🚀
