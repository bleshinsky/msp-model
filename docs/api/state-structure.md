# MSP State Structure

Detailed documentation of MSP's internal state structure and data formats.

## Session State

The core session state object contains all information about an active or completed session.

### Session Object Structure

```json
{
  "id": "msp-2025-01-16-093042",
  "project": "TaskAPI",
  "user": "developer@example.com",
  "startTime": "2025-01-16 09:30:42",
  "endTime": "2025-01-16 17:45:18",
  "status": "completed",
  "duration": 8.25,
  "startProgress": 45,
  "endProgress": 67,
  "summary": "Implemented authentication system",
  "updates": [...],
  "decisions": [...],
  "entities": [...],
  "blockers": [...],
  "queries": [...]
}
```

### Field Descriptions

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | string | Unique session identifier (format: msp-YYYY-MM-DD-HHMMSS) | Yes |
| `project` | string | Project name | Yes |
| `user` | string | User identifier (email or username) | Yes |
| `startTime` | string | ISO 8601 timestamp of session start | Yes |
| `endTime` | string | ISO 8601 timestamp of session end | No |
| `status` | string | Session status: "active", "completed", "crashed" | Yes |
| `duration` | number | Session duration in hours (calculated) | No |
| `startProgress` | number | Progress percentage at start (0-100) | Yes |
| `endProgress` | number | Progress percentage at end (0-100) | Yes |
| `summary` | string | Session summary provided at end | No |
| `updates` | array | Progress updates during session | Yes |
| `decisions` | array | Decisions made during session | Yes |
| `entities` | array | Entities created during session | Yes |
| `blockers` | array | Blockers encountered | Yes |
| `queries` | array | Generated Neo4j queries (Standard only) | No |

## Update Object Structure

Each progress update is stored with metadata:

```json
{
  "time": "14:30",
  "timestamp": "2025-01-16 14:30:15",
  "description": "Implemented JWT refresh token endpoint",
  "progress": 55,
  "tags": ["auth", "api"],
  "autoDetected": {
    "type": "entity",
    "extracted": "refresh token endpoint"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `time` | string | Human-readable time (HH:MM) |
| `timestamp` | string | Full ISO 8601 timestamp |
| `description` | string | Update description |
| `progress` | number | Progress at this point (-1 if not specified) |
| `tags` | array | Tags extracted or assigned |
| `autoDetected` | object | Auto-detected patterns (decision/entity/blocker) |

## Decision Object Structure

Architectural and technical decisions:

```json
{
  "id": "dec-2025-01-16-143015",
  "content": "Using Redis for session storage",
  "rationale": "Better performance than database sessions, built-in TTL",
  "alternatives": ["PostgreSQL sessions", "JWT only", "In-memory"],
  "timestamp": "2025-01-16 14:30:15",
  "impact": "high",
  "category": "architecture",
  "relatedEntities": ["SessionManager", "RedisClient"]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique decision ID |
| `content` | string | The decision made |
| `rationale` | string | Why this decision was made |
| `alternatives` | array | Other options considered |
| `timestamp` | string | When decision was made |
| `impact` | string | Impact level: low/medium/high |
| `category` | string | Decision category |
| `relatedEntities` | array | Related code entities |

## Entity Object Structure

Code entities created during session:

```json
{
  "name": "AuthController",
  "type": "class",
  "path": "src/controllers/auth.controller.ts",
  "description": "Handles authentication endpoints",
  "timestamp": "2025-01-16 15:20:00",
  "properties": {
    "language": "TypeScript",
    "framework": "Express",
    "methods": ["login", "logout", "refresh", "validate"]
  }
}
```

## Blocker Object Structure

Issues and impediments:

```json
{
  "id": "blk-2025-01-16-162000",
  "description": "CORS issues with refresh token endpoint",
  "category": "technical",
  "severity": "high",
  "createdAt": "2025-01-16 16:20:00",
  "resolvedAt": "2025-01-16 16:45:00",
  "resolution": "Added credentials: true to CORS config",
  "status": "resolved",
  "relatedUpdates": ["upd-143015", "upd-164500"]
}
```

## Configuration Structure

MSP configuration format:

```json
{
  "project": "MyProject",
  "user": {
    "name": "Developer Name",
    "email": "dev@example.com",
    "timezone": "America/New_York"
  },
  "neo4j": {
    "uri": "bolt://localhost:7687",
    "username": "neo4j",
    "database": "neo4j",
    "projectStateName": "MSP Current State"
  },
  "obsidian": {
    "vaultPath": "C:\\Obsidian\\MyVault",
    "templatesPath": "Templates",
    "dailyNotesPath": "Daily Notes",
    "projectsPath": "Projects"
  },
  "linear": {
    "teamId": "uuid",
    "projectId": "uuid",
    "activeIssue": "PROJ-123",
    "labels": {
      "session": "msp-session",
      "decision": "architecture-decision"
    }
  },
  "features": {
    "autoClipboard": true,
    "progressTracking": true,
    "decisionTracking": true,
    "minProgressChange": 1,
    "sessionTimeout": 24,
    "debugMode": false
  },
  "paths": {
    "stateDir": ".msp/state",
    "archiveDir": ".msp/archive",
    "logsDir": ".msp/logs"
  }
}
```

## File System Layout

### MSP Lite

```
project-root/
├── msp.ps1
└── .msp/
    ├── state/
    │   └── current-session.json
    ├── archive/
    │   ├── sessions/
    │   │   └── msp-2025-01-16-093042.json
    │   └── daily/
    │       └── 2025-01-16.json
    └── config.json
```

### MSP Standard

```
project-root/
├── msp.ps1
├── scripts/
├── config/
│   └── msp-config.json
└── .msp/
    ├── state/
    │   ├── current-session.json
    │   └── recovery/
    ├── archive/
    │   ├── sessions/
    │   ├── queries/
    │   └── exports/
    ├── cache/
    │   ├── neo4j/
    │   └── linear/
    └── logs/
```

## Neo4j Graph Schema

### Node Types

**Session Node**
```cypher
(:Session {
  id: string,
  name: string,
  user: string,
  project: string,
  startTime: datetime,
  endTime: datetime,
  status: string,
  progress: integer,
  duration: float,
  summary: string
})
```

**Decision Node**
```cypher
(:Decision {
  id: string,
  content: string,
  rationale: string,
  timestamp: datetime,
  impact: string,
  category: string
})
```

**Entity Node**
```cypher
(:Entity {
  name: string,
  type: string,
  createdAt: datetime,
  path: string,
  language: string
})
```

**ProjectState Node**
```cypher
(:ProjectState {
  name: string,
  project: string,
  progress: integer,
  phase: string,
  lastUpdated: datetime,
  observations: [string]
})
```

### Relationship Types

- `(Session)-[:HAS_PROGRESS]->(Progress)`
- `(Session)-[:MADE_DECISION]->(Decision)`
- `(Session)-[:CREATED_ENTITY]->(Entity)`
- `(Session)-[:ENCOUNTERED_BLOCKER]->(Blocker)`
- `(Session)-[:FOLLOWS]->(Session)`
- `(Decision)-[:CONSIDERED]->(Alternative)`
- `(Entity)-[:RELATES_TO]->(Entity)`

## Data Retention

- **Active Sessions**: Kept in state directory
- **Completed Sessions**: Archived immediately
- **Archive Retention**: Unlimited by default
- **Cache Data**: 7 days (configurable)
- **Logs**: 30 days rolling

## Export Formats

### AI Context Format
```
PROJECT CONTEXT
===============
Project: TaskAPI
Language: TypeScript
Framework: Express
Progress: 67%

RECENT DECISIONS
===============
- Redis for sessions (performance)
- JWT with refresh tokens (security)
- UUID keys (distributed systems)

CURRENT STATE
============
Working on: Payment integration
Blockers: None
Next: Webhook implementation
```

### JSON Export Format
Includes full session object with all relationships

### Markdown Export Format
Human-readable summary with tables and sections
