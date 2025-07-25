# The R³ Protocol

## Route - Recall - Record

The R³ Protocol is the core philosophy behind MSP. It transforms chaotic development into a structured, memory-augmented workflow that preserves context across time and tools.

```
    ROUTE → RECALL → RECORD
      ↑                    ↓
      └────────────────────┘
```

## The Three Phases

### 1. ROUTE: Where am I going?

Every session begins with intention. Route establishes your destination and waypoints:

- **Define the destination**: What will success look like?
- **Set waypoints**: Break down the journey into trackable milestones
- **Establish constraints**: Time, resources, dependencies
- **Choose the path**: Technical approach and architecture decisions

**Example Route Phase**:
```powershell
.\msp.ps1 start --project "Authentication System" --epic "User Login"

# MSP prompts:
# → What's the goal for this session?
# → What progress markers will you track?
# → Any blockers or dependencies?
```

### 2. RECALL: Where have I been?

Context is everything. Recall restores your mental state instantly:

- **Load session history**: Previous decisions, progress, blockers
- **Surface relevant knowledge**: Related code, documentation, discussions
- **Identify patterns**: What worked before in similar situations
- **Restore mental model**: Get back to productive state in seconds

**Example Recall Phase**:
```powershell
.\msp.ps1 context

# MSP returns:
# → Last session: Implemented JWT tokens (yesterday, 3h)
# → Decision: Chose 15min token expiry for security
# → Blocker: Refresh token rotation complexity
# → Progress: 45% → 67% (Auth module)
# → Next: Implement refresh token endpoint
```

### 3. RECORD: What happened here?

Knowledge persists only when captured. Record makes every moment count:

- **Track decisions**: Not just what, but why
- **Log progress**: Quantify advancement, however small
- **Document blockers**: Learn from obstacles
- **Create artifacts**: Code, configs, learnings

**Example Record Phase**:
```powershell
.\msp.ps1 update "Implemented refresh token rotation" 72
.\msp.ps1 decide "Using Redis for token blacklist - simpler than DB table"
.\msp.ps1 block "CORS issues with refresh endpoint"
.\msp.ps1 end --summary "Auth system 72% complete, refresh tokens working"
```

## Why R³ Works

### 1. **Cognitive Offloading**
Your brain is for thinking, not remembering. R³ externalizes memory to a persistent knowledge graph.

### 2. **Context Preservation**
Every decision, every rationale, every lesson learned becomes queryable knowledge.

### 3. **Momentum Maintenance**
No more "where was I?" moments. Jump back in exactly where you left off.

### 4. **AI Amplification**
Feed complete context to AI assistants. They understand your entire journey, not just the current question.

## R³ vs Traditional Development

| Traditional | R³ Protocol |
|------------|-------------|
| Start coding immediately | Route first, code with purpose |
| Rely on memory | Recall from knowledge graph |
| Forget decisions | Record rationale permanently |
| Context loss between sessions | Context persists forever |
| AI starts fresh each time | AI has complete project history |

## Implementation in MSP

MSP enforces R³ through mandatory checkpoints:

1. **Session Start** triggers ROUTE
   - Load project state
   - Define session goals
   - Set progress markers

2. **Continuous Updates** enable RECALL
   - Query previous decisions
   - Surface relevant context
   - Track progress delta

3. **Session End** completes RECORD
   - Capture all decisions
   - Document learnings
   - Update knowledge graph


## R³ in Practice

```powershell
# Monday morning - where was I?
.\msp.ps1 start

# ROUTE: MSP shows your destination
> Current Sprint: Payment Integration
> This session: Implement Stripe webhooks
> Progress: 67% → Target 75%

# RECALL: MSP restores context
> Last decision: Use raw body parsing for signatures
> Active blocker: Webhook timeout issues
> Related sessions: 3 previous webhook implementations

# Work happens here...

# RECORD: Capture everything
.\msp.ps1 update "Fixed timeout with async processing" 70
.\msp.ps1 decide "Queue webhooks through Redis for reliability"
.\msp.ps1 resolve "Webhook timeout issues - used job queue"
.\msp.ps1 end

# Your future self thanks you
```

