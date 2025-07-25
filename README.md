# msp-model
# MSP - Mandatory Session Protocol

> Never lose context again. A developer productivity tool for the context engineering era.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Neo4j Compatible](https://img.shields.io/badge/Neo4j-4.4%2B-green)](https://neo4j.com)

## What is MSP?

MSP (Mandatory Session Protocol) is a model for context engineering that ensures you never lose track of your development work. It enforces structured session management across your entire toolchain, creating a persistent knowledge graph of your project's evolution.

### The Problem: Vibe Coding

**Vibe Coding** (noun): The practice of using AI assistants through unstructured, conversational interactions without persistent context, resulting in:

- 🤯 **Context Amnesia**: Every conversation starts from zero
- 🔄 **Repeated Work**: " Context hallucination results in code debt
- 🤖 **Shallow AI Help**: "Let me explain my entire project again..."
- 📉 **Inconsistent responses**: Different answers to similar questions
-   **Lost decisions**: You've switched integration but your AI assistant only remembers the old one

### The Vibe Coding Loop of Doom

```
Start new chat → Explain context → Get answer → Close chat → Forget everything → Repeat
```

### The Solution: Context Engineering

**Context Engineering** (noun): The systematic practice of capturing, structuring, and maintaining development context to enable deep, consistent, and evolving AI assistance.

### How MSP Helps

MSP implements the looping **R³ Framework* (Route-Recall-Record) to create a memory-augmented development workflow:

```
    ROUTE → RECALL → RECORD
      ↑                    ↓
      └────────────────────┘
```

## Quick Start

### Option 1: MSP Lite (5 minutes)

Zero dependencies. Just PowerShell.

```powershell
# Download and start
iwr -Uri "https://github.com/msp-model/msp/raw/main/lite/msp-lite.ps1" -OutFile "msp.ps1"
.\msp.ps1 start
```

### Option 2: MSP Standard (Recommended)

Full context engineering with Neo4j, Obsidian, and Linear.

NOTE: You can switch any of these out for your tool of choice. The important thing is to have all three functions covered. Go to http://sessionprotocol.dev to find out more.

```powershell
# Clone and setup
git clone https://github.com/msp-model/msp-model.git
cd msp/standard
.\setup.ps1
```

### Option 3: MSP Advanced (COMING SOON)

Enterprise features, team collaboration, custom integrations.


## Core Features

### 🧠 **Knowledge Graph**
Every session, decision, and progress update becomes a queryable node in Neo4j. Your project's entire history at your fingertips.

### 🤖 **AI Context Export**
Feed complete project context to any AI with one command. Claude, GPT, or Copilot get instant understanding.

### 📊 **Progress Tracking**
Quantify your work with granular progress updates. Know exactly where you are and what's next.

### 💡 **Decision History**
Never wonder "why did we do it this way?" again. Every architectural choice is documented with rationale.

### 🔄 **Session Recovery**
Start where you left off with complete context.

### 📝 **Tool Integration**
- **Neo4j**: Knowledge graph and relationships
- **Obsidian**: Markdown documentation
- **Linear**: Issue tracking and planning
- **Git**: Version control integration

## How It Works

### 1. Start Your Session
```powershell
.\msp.ps1 start

# MSP loads your context:
# → Current project state
# → Recent decisions
# → Active blockers
# → Progress metrics
```

### 2. Track As You Work
```powershell
.\msp.ps1 update "Implemented OAuth flow" 45
.\msp.ps1 decide "Using JWT with 15min expiry - better security"
.\msp.ps1 block "CORS issues with refresh endpoint"
```

### 3. End With Context Captured
```powershell
.\msp.ps1 end

# MSP saves everything:
# → Session duration and progress
# → All decisions with rationale
# → Generated Neo4j queries
# → Updated documentation
# → Automated validation across the three tools - knowledge graph, task/project management and documentation - ensures everything is in sync and errors are not creeping in.
```

## Version Comparison

| Feature | MSP Lite | MSP Standard | MSP Advanced (COMING SOON) |
|---------|----------|--------------|--------------|
| Session Tracking | ✅ JSON files | ✅ Neo4j | ✅ Neo4j + Custom |
| Progress Tracking | ✅ Basic | ✅ Full | ✅ Team metrics |
| AI Context Export | ✅ | ✅ | ✅ Custom formats |
| Obsidian Integration | ❌ | ✅ | ✅ |
| Linear Integration | ❌ | ✅ | ✅ |
| Team Features | ❌ | ❌ | ✅ |
| Setup Time | 5 min | 45 min | Custom |
| Dependencies | None | Neo4j, etc | Varies |

## Documentation

- **Concepts**
  - [Context Engineering](./docs/concepts/context-engineering.md) - Why MSP exists
  - [The R³ Protocol](./docs/concepts/r3-protocol.md) - Route, Recall, Record
  - [Why MSP](./docs/concepts/why-msp.md) - Philosophy and principles

- **Guides**
  - [Quickstart](./docs/guides/quickstart.md) - Get running in 5 minutes
  - [Configuration](./docs/guides/configuration.md) - Customize MSP
  - [Troubleshooting](./docs/guides/troubleshooting.md) - Common issues

- **API Reference**
  - [Commands](./docs/api/commands.md) - All MSP commands
  - [State Structure](./docs/api/state-structure.md) - Data format
  - [Integration API](./docs/api/integration-api.md) - Extend MSP

## Examples

Check the `examples/` directory for real-world usage:

- `solo-developer/` - Individual productivity workflows
- `small-team/` - Team collaboration patterns  (COMING SOON)
- `enterprise/` - Large-scale implementations (COMING SOON)

## Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### Development Setup

```powershell
# Clone the repo
git clone https://github.com/msp-model/msp-model.git
cd msp-model

```


## License

MSP is open source under the [MIT License](./LICENSE).

---

**Ready to never lose context again?**

```powershell
# Your journey starts here
.\msp.ps1 start
```
