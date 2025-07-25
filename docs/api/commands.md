# MSP Commands Reference

Complete reference for all MSP commands across all versions.

## Core Commands

### `msp start`
Starts a new MSP session.

**Syntax:**
```powershell
.\msp.ps1 start [[-Project] <string>] [[-Description] <string>] [[-Progress] <int>]
```

**Parameters:**
- `-Project` (optional): Project name. Defaults to config value or "Default"
- `-Description` (optional): Initial session description
- `-Progress` (optional): Starting progress percentage (0-100). Defaults to last known progress

**Examples:**
```powershell
# Simple start
.\msp.ps1 start

# Start with project name
.\msp.ps1 start -Project "E-commerce API"

# Start with progress
.\msp.ps1 start -Progress 45
```

**Output:**
- Session ID
- Neo4j queries (Standard version)
- Previous session context (if available)

---

### `msp update`
Records a progress update during active session.

**Syntax:**
```powershell
.\msp.ps1 update <Description> [Progress]
```

**Parameters:**
- `Description` (required): What was accomplished
- `Progress` (optional): Current progress percentage (0-100)

**Examples:**
```powershell
# Simple update
.\msp.ps1 update "Implemented user authentication"

# Update with progress
.\msp.ps1 update "Completed login endpoint" 35

# Update with progress decrease
.\msp.ps1 update "Reverted changes - wrong approach" 30
```

**Automatic Detection:**
- Decisions: Keywords like "decided", "chose", "will use"
- Entities: Keywords like "created", "implemented", "built"
- Blockers: Keywords like "blocked", "issue", "problem"

---

### `msp end`
Ends the current session and generates final outputs.

**Syntax:**
```powershell
.\msp.ps1 end [[-Summary] <string>]
```

**Parameters:**
- `-Summary` (optional): Session summary or key accomplishments

**Examples:**
```powershell
# Simple end
.\msp.ps1 end

# End with summary
.\msp.ps1 end -Summary "Authentication system complete"
```

**Output:**
- Session duration
- Progress delta
- All generated queries (Standard)
- Archive location

---

### `msp status`
Shows current session status.

**Syntax:**
```powershell
.\msp.ps1 status
```

**Output:**
- Session ID and duration
- Current progress
- Recent updates
- Active blockers

---

### `msp decide`
Records an architectural or technical decision.

**Syntax:**
```powershell
.\msp.ps1 decide <Decision> [[-Rationale] <string>] [[-Alternatives] <string[]>]
```

**Parameters:**
- `Decision` (required): The decision made
- `-Rationale` (optional): Why this decision was made
- `-Alternatives` (optional): Other options considered

**Examples:**
```powershell
# Simple decision
.\msp.ps1 decide "Using Redis for session storage"

# Decision with rationale
.\msp.ps1 decide "JWT for auth" -Rationale "Stateless and scalable"

# Decision with alternatives
.\msp.ps1 decide "PostgreSQL for database" -Rationale "Need ACID compliance" -Alternatives @("MongoDB", "MySQL")
```

---

### `msp block`
Records a blocker or issue.

**Syntax:**
```powershell
.\msp.ps1 block <Description> [[-Category] <string>]
```

**Parameters:**
- `Description` (required): Description of the blocker
- `-Category` (optional): Type of blocker (technical, external, resource)

**Examples:**
```powershell
# Simple blocker
.\msp.ps1 block "CORS issues with third-party API"

# Categorized blocker
.\msp.ps1 block "Waiting for API credentials" -Category "external"
```

---

### `msp resolve`
Marks a blocker as resolved.

**Syntax:**
```powershell
.\msp.ps1 resolve <BlockerDescription> [[-Solution] <string>]
```

**Parameters:**
- `BlockerDescription` (required): Description matching the blocker
- `-Solution` (optional): How it was resolved

**Examples:**
```powershell
# Simple resolution
.\msp.ps1 resolve "CORS issues"

# Resolution with solution
.\msp.ps1 resolve "CORS issues" -Solution "Added proxy endpoint"
```

---

### `msp context`
Exports session context for AI assistants or documentation.

**Syntax:**
```powershell
.\msp.ps1 context [[-Format] <string>] [[-Days] <int>]
```

**Parameters:**
- `-Format` (optional): Output format (ai, json, markdown). Default: ai
- `-Days` (optional): Days of history to include. Default: 7

**Examples:**
```powershell
# Export for AI
.\msp.ps1 context | clip

# Export as JSON
.\msp.ps1 context -Format json

# Export last 30 days
.\msp.ps1 context -Days 30
```

---

### `msp recover`
Recovers from interrupted or crashed sessions.

**Syntax:**
```powershell
.\msp.ps1 recover [[-SessionId] <string>] [-List] [-Force]
```

**Parameters:**
- `-SessionId` (optional): Specific session to recover
- `-List`: List all recoverable sessions
- `-Force`: Force recovery even if session seems corrupted

**Examples:**
```powershell
# Interactive recovery
.\msp.ps1 recover

# List sessions
.\msp.ps1 recover -List

# Recover specific session
.\msp.ps1 recover -SessionId "msp-2025-01-16-093042"
```

---

### `msp config`
Manages MSP configuration.

**Syntax:**
```powershell
.\msp.ps1 config [show | edit | <key> <value>]
```

**Operations:**
- `show`: Display current configuration
- `edit`: Open config in default editor
- `<key> <value>`: Set configuration value

**Examples:**
```powershell
# Show config
.\msp.ps1 config show

# Edit config
.\msp.ps1 config edit

# Set value
.\msp.ps1 config project "My New Project"
.\msp.ps1 config neo4j.uri "bolt://localhost:7687"
.\msp.ps1 config linear.activeIssue "PROJ-123"
```

---

## Version-Specific Commands

### MSP Lite Only

All core commands work the same, but with:
- No external integrations
- JSON file storage only
- Simplified output

### MSP Standard Additional

**`msp validate`**
Validates system state and checks integrations.

```powershell
.\msp.ps1 validate
```

**`msp git`**
Generates git commit messages from session.

```powershell
# Generate commit message
.\msp.ps1 git

# Commit with generated message
.\msp.ps1 git commit

# Commit and push
.\msp.ps1 git commit push
```

### MSP Advanced Additional

See Advanced documentation for team and enterprise commands.

## Command Aliases

For convenience, these aliases are available:

| Alias | Full Command |
|-------|--------------|
| `msp s` | `msp start` |
| `msp u` | `msp update` |
| `msp e` | `msp end` |
| `msp d` | `msp decide` |
| `msp b` | `msp block` |
| `msp r` | `msp resolve` |
| `msp c` | `msp context` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | No active session |
| 2 | Session already active |
| 3 | Configuration error |
| 4 | Integration error |
| 5 | State corruption |

## Environment Variables

MSP respects these environment variables:

- `MSP_PROJECT`: Default project name
- `MSP_CONFIG_PATH`: Custom config location
- `MSP_STATE_DIR`: State directory location
- `MSP_DEBUG`: Enable debug output (true/false)
- `MSP_NO_CLIPBOARD`: Disable clipboard integration
