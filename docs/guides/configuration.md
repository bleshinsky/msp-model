# MSP Configuration Guide

Complete guide to configuring MSP for your workflow.

## Configuration Overview

MSP uses a layered configuration approach:

1. **Default Configuration** - Built-in defaults
2. **User Configuration** - Your custom settings
3. **Environment Variables** - Override specific values
4. **Command Line** - Runtime overrides

## Configuration File Location

### MSP Lite
```
.msp/config.json
```

### MSP Standard
```
config/msp-config.json
```

## Basic Configuration

### Minimal Configuration (MSP Lite)

```json
{
  "project": "MyProject",
  "user": {
    "name": "Your Name",
    "email": "you@example.com"
  }
}
```

### Standard Configuration (MSP Standard)

```json
{
  "project": "MyProject",
  "user": {
    "name": "Your Name",
    "email": "you@example.com",
    "timezone": "America/New_York"
  },
  "neo4j": {
    "uri": "bolt://localhost:7687",
    "username": "neo4j",
    "database": "neo4j"
  },
  "obsidian": {
    "vaultPath": "C:\\Obsidian\\MyVault"
  },
  "linear": {
    "teamId": "your-team-uuid",
    "projectId": "your-project-uuid"
  }
}
```

## Configuration Options

### Core Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `project` | string | "Default" | Current project name |
| `user.name` | string | $env:USERNAME | Your display name |
| `user.email` | string | null | Your email address |
| `user.timezone` | string | System TZ | Your timezone |

### Feature Flags

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `features.autoClipboard` | boolean | true | Auto-copy queries to clipboard |
| `features.progressTracking` | boolean | true | Enable progress tracking |
| `features.decisionTracking` | boolean | true | Auto-detect decisions |
| `features.minProgressChange` | number | 1 | Minimum progress change to track |
| `features.sessionTimeout` | number | 24 | Hours before session timeout |
| `features.debugMode` | boolean | false | Enable debug output |

### Path Configuration

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `paths.stateDir` | string | ".msp/state" | Session state storage |
| `paths.archiveDir` | string | ".msp/archive" | Completed sessions |
| `paths.logsDir` | string | ".msp/logs" | Log files location |

## Integration Configuration

### Neo4j Configuration

```json
{
  "neo4j": {
    "uri": "bolt://localhost:7687",
    "username": "neo4j",
    "database": "neo4j",
    "projectStateName": "MSP Current State",
    "sessionPrefix": "MSP Session",
    "connectionTimeout": 30000,
    "maxRetries": 3
  }
}
```

**Getting Neo4j Credentials:**
1. Open Neo4j Desktop
2. Start your database
3. Click "Manage" → "Settings"
4. Note the bolt port (usually 7687)
5. Username is typically "neo4j"

### Obsidian Configuration

```json
{
  "obsidian": {
    "vaultPath": "C:\\Users\\YourName\\Obsidian\\MyVault",
    "dailyNotesPath": "Daily Notes",
    "projectsPath": "Projects",
    "decisionsPath": "Decisions",
    "templatesPath": "Templates",
    "dateFormat": "YYYY-MM-DD",
    "autoOpen": false
  }
}
```

**Finding Your Vault Path:**
1. Open Obsidian
2. Settings → About
3. Look for "Current vault path"
4. Copy the full path

### Linear Configuration

```json
{
  "linear": {
    "teamId": "b5f3e8a1-5c7d-4e2f-9a1b-8c3d5e7f9a2b",
    "projectId": "a2b4c6d8-1e3f-5a7b-9c1d-3e5f7a9b1c3d",
    "activeIssue": "PROJ-123",
    "defaultPriority": 3,
    "labels": {
      "session": "msp-session",
      "decision": "architecture-decision",
      "blocker": "blocker"
    },
    "updateFrequency": 5,
    "significantKeywords": ["completed", "implemented", "fixed"]
  }
}
```

**Getting Linear IDs:**
1. Open Linear
2. Navigate to your team
3. Settings → API → Personal API keys
4. Generate a key
5. Use the API explorer to find team/project IDs

Or use Linear MCP tools:
```powershell
# Ask Claude with Linear MCP:
# "List my Linear teams and their IDs"
# "Show me the ID for project 'MyProject'"
```

## Environment Variables

Override configuration with environment variables:

### Core Variables
```powershell
# PowerShell
$env:MSP_PROJECT = "MyProject"
$env:MSP_USER_NAME = "John Doe"
$env:MSP_USER_EMAIL = "john@example.com"
$env:MSP_DEBUG = "true"

# Bash
export MSP_PROJECT="MyProject"
export MSP_USER_NAME="John Doe"
export MSP_USER_EMAIL="john@example.com"
export MSP_DEBUG=true
```

### Integration Variables
```powershell
# Neo4j
$env:MSP_NEO4J_URI = "bolt://localhost:7687"
$env:MSP_NEO4J_USERNAME = "neo4j"
$env:MSP_NEO4J_PASSWORD = "your-password"

# Obsidian
$env:MSP_OBSIDIAN_VAULT = "C:\Obsidian\WorkVault"

# Linear
$env:MSP_LINEAR_TEAM = "team-uuid"
$env:MSP_LINEAR_PROJECT = "project-uuid"
```

## Configuration Commands

### View Current Configuration
```powershell
.\msp.ps1 config show
```

### Edit Configuration
```powershell
# Open in default editor
.\msp.ps1 config edit

# Set specific value
.\msp.ps1 config project "NewProject"
.\msp.ps1 config neo4j.uri "bolt://remotehost:7687"
```

### Validate Configuration
```powershell
.\msp.ps1 validate
```

## Per-Project Configuration

Create project-specific configs:

```
my-project/
├── .msp/
│   └── config.json    # Project-specific config
└── msp.ps1            # Uses local config first
```

## Configuration Profiles

Create profiles for different contexts:

### config/profiles/work.json
```json
{
  "project": "WorkProject",
  "user": {
    "email": "me@company.com"
  },
  "linear": {
    "teamId": "work-team-id"
  }
}
```

### config/profiles/personal.json
```json
{
  "project": "SideProject",
  "user": {
    "email": "me@personal.com"
  },
  "features": {
    "progressTracking": false
  }
}
```

### Switch Profiles
```powershell
# Set profile
$env:MSP_PROFILE = "work"

# Or copy profile to main config
Copy-Item config/profiles/work.json config/msp-config.json
```

## Security Best Practices

### 1. **Never Commit Secrets**
```json
// msp-config.json - DON'T DO THIS
{
  "neo4j": {
    "password": "actual-password"  // WRONG!
  }
}
```

Instead, use environment variables or credential managers.

### 2. **Use .gitignore**
```gitignore
# Always ignore
msp-config.json
config/*-config.json
!config/*-config.example.json
```

### 3. **Secure Credential Storage**

Windows Credential Manager:
```powershell
# Store credential
$cred = Get-Credential -UserName "neo4j"
$cred.Password | ConvertFrom-SecureString | Out-File neo4j.cred

# Load credential
$securePassword = Get-Content neo4j.cred | ConvertTo-SecureString
```

### 4. **Minimal Permissions**
- Use read-only API keys where possible
- Limit integration permissions
- Rotate credentials regularly

## Common Configuration Scenarios

### Solo Developer
```json
{
  "project": "MyAPI",
  "features": {
    "progressTracking": true,
    "autoClipboard": true
  },
  "obsidian": {
    "vaultPath": "C:\\Notes\\Dev"
  }
}
```

### Team with Linear
```json
{
  "project": "TeamProject",
  "user": {
    "name": "Jane Developer",
    "email": "jane@team.com"
  },
  "linear": {
    "teamId": "eng-team-uuid",
    "projectId": "q4-project-uuid",
    "updateFrequency": 5
  },
  "features": {
    "minProgressChange": 5
  }
}
```

### Enterprise Setup
```json
{
  "project": "EnterpriseApp",
  "neo4j": {
    "uri": "bolt+s://neo4j.company.com:7687",
    "database": "msp_prod"
  },
  "paths": {
    "stateDir": "\\\\fileserver\\msp\\state",
    "archiveDir": "\\\\fileserver\\msp\\archive"
  },
  "features": {
    "debugMode": false,
    "sessionTimeout": 8
  }
}
```

## Troubleshooting Configuration

### Configuration Not Loading
1. Check file exists: `config/msp-config.json`
2. Validate JSON syntax
3. Check file permissions
4. Look for errors in `.msp/logs/`

### Integration Not Working
1. Run `.\msp.ps1 validate`
2. Test connection separately
3. Check credentials
4. Verify network access

### Wrong Configuration Used
Check precedence order:
1. Command line args (highest)
2. Environment variables
3. Local `.msp/config.json`
4. User `config/msp-config.json`
5. Default values (lowest)

## Migration Guide

### From MSP Lite to Standard
```powershell
# 1. Copy configuration
Copy-Item .msp/config.json standard/config/msp-config.json

# 2. Add integration settings
.\msp.ps1 config neo4j.uri "bolt://localhost:7687"
.\msp.ps1 config obsidian.vaultPath "C:\Obsidian\Vault"

# 3. Migrate session data
.\scripts\migrate-sessions.ps1
```

### Version Updates
Always backup before updating:
```powershell
# Backup current config
Copy-Item config/msp-config.json config/msp-config.backup.json

# Update MSP
git pull

# Check for config changes
.\msp.ps1 validate
```

## Get Help

- Example configs: `config/*-config.example.json`
- Validation: `.\msp.ps1 validate`
- Community: [Discord #configuration]
- Docs: [https://docs.msp-framework.dev/config]
