# MSP Lite - Zero-Dependency Session Tracking

The simplest way to start using MSP. No databases, no external tools - just PowerShell and JSON files.

## 🚀 Quick Start (5 minutes)

### One-Line Install
```powershell
# Windows/Mac/Linux with PowerShell 7+
iwr -useb https://raw.githubusercontent.com/yourusername/msp/main/lite/install.ps1 | iex
```

### Manual Install
```powershell
# Download the script
curl -O https://raw.githubusercontent.com/yourusername/msp/main/lite/msp-lite.ps1

# Make it accessible (optional)
# Windows: Add to PATH or create alias
# Mac/Linux: chmod +x msp-lite.ps1 && sudo ln -s $(pwd)/msp-lite.ps1 /usr/local/bin/msp-lite
```

## 📖 Usage

### Basic Workflow
```powershell
# Start your work session
msp-lite start

# Track your progress
msp-lite update "Created user authentication module" 25
msp-lite update "Added JWT token validation"
msp-lite update "Decided to use refresh tokens for better security"

# End your session
msp-lite end
```

### Check Status
```powershell
# See current session
msp-lite status

# Recall previous work
msp-lite recall

# Export context for AI
msp-lite context
```

## 🎯 Features

### Automatic Decision Tracking
MSP Lite automatically detects decisions when you use keywords like:
- "decided", "chose", "selected", "picked"
- "will use", "going with"

Example:
```powershell
msp-lite update "Decided to use PostgreSQL instead of MongoDB"
# ✅ Update recorded
# 💡 Decision tracked!
```

### Progress Tracking
Track quantifiable progress throughout your session:
```powershell
msp-lite update "Completed API endpoints" 50
# ✅ Update recorded
# 📊 Progress: 50%
```

### Context Export
Export your complete context for AI assistants:
```powershell
msp-lite context
# Copies to clipboard and saves to file
# Paste into Claude, GPT, or Cursor for instant context
```

## 📁 Data Storage

MSP Lite stores all data in `~/.msp-lite/`:
```
~/.msp-lite/
├── current-session.json      # Active session
├── session-history.json      # Session summaries
├── decisions.json           # All decisions
├── progress-tracking.json   # Daily progress
└── archive/                # Completed sessions
    └── msp-lite-20250116-093042.json
```

## 🔧 Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `start` | Begin a new session | `msp-lite start` |
| `update` | Add update with optional progress | `msp-lite update "Fixed bug" 30` |
| `end` | Complete current session | `msp-lite end` |
| `status` | Show current session info | `msp-lite status` |
| `recall` | View recent work history | `msp-lite recall` |
| `context` | Export full context | `msp-lite context` |
| `help` | Show help information | `msp-lite help` |

## 💡 Best Practices

1. **Start Every Work Session**: Always run `msp-lite start` when you begin work
2. **Update Frequently**: Track progress as you work, not just at the end
3. **Be Specific**: "Implemented OAuth2" is better than "Did some auth work"
4. **Track Decisions**: Document why you chose specific approaches
5. **End Sessions**: Always run `msp-lite end` before stopping work

## 🤝 Integration Examples

### With AI Assistants
```powershell
# Export context and paste into Claude/GPT
msp-lite context | clip  # Windows
msp-lite context | pbcopy # Mac
```

### With Git
```powershell
# Use session summary for commit messages
msp-lite status
git commit -m "Session: Implemented authentication (25% progress)"
```

### With VS Code
Add to your tasks.json:
```json
{
  "label": "Start MSP Session",
  "type": "shell",
  "command": "msp-lite start"
}
```

## 🎓 Examples

See the [examples](./examples) directory for:
- [Basic Workflow](./examples/basic-workflow.ps1)
- [AI Integration](./examples/ai-integration.ps1)
- [Team Handoffs](./examples/team-handoff.ps1)

## ❓ FAQ

**Q: Where is my data stored?**
A: In `~/.msp-lite/` (your home directory)

**Q: Can I use this with my team?**
A: MSP Lite is designed for individual use. For team features, see MSP Standard or Advanced.

**Q: How do I backup my data?**
A: Simply backup the `~/.msp-lite/` directory

**Q: Can I customize the keywords for decision detection?**
A: Edit the `$decisionKeywords` array in the script

## 📈 Upgrading to MSP Standard

When you're ready for more features:
- Neo4j knowledge graph
- Obsidian integration
- Linear issue tracking
- Team collaboration

See [MSP Standard](../standard) for upgrade instructions.

## 🐛 Troubleshooting

### "Command not found"
- Ensure PowerShell 7+ is installed
- Check that the script is in your PATH or use the full path

### "Cannot create directory"
- Check permissions on your home directory
- Try running as administrator (Windows) or with sudo (Mac/Linux)

### "Session already active"
- End the current session: `msp-lite end`
- Or check status: `msp-lite status`

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.

---

**MSP Lite**: The simplest way to never lose context again. 🚀
