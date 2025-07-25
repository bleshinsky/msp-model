# MSP Troubleshooting Guide

This guide helps you resolve common issues with MSP across all versions.

## Table of Contents

- [General Issues](#general-issues)
- [MSP Lite Issues](#msp-lite-issues)
- [MSP Standard Issues](#msp-standard-issues)
- [Integration Issues](#integration-issues)
- [Performance Issues](#performance-issues)
- [Data Recovery](#data-recovery)
- [Getting Help](#getting-help)

## General Issues

### PowerShell Version Errors

**Problem**: "This script requires PowerShell 7.0 or higher"

**Solution**:
```powershell
# Check your PowerShell version
$PSVersionTable.PSVersion

# Install PowerShell 7+ (Windows)
winget install Microsoft.PowerShell

# Install PowerShell 7+ (macOS)
brew install powershell

# Install PowerShell 7+ (Linux)
# See: https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-linux
```

### Execution Policy Errors

**Problem**: "Script cannot be loaded because running scripts is disabled"

**Solution**:
```powershell
# For current user only (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for current session only
powershell.exe -ExecutionPolicy Bypass -File .\msp.ps1
```

### Path or File Not Found

**Problem**: "Cannot find path" or "File not found" errors

**Solution**:
1. Ensure you're in the correct directory
2. Check file paths in your commands
3. Use full paths if relative paths fail:
   ```powershell
   # Instead of
   .\msp.ps1
   
   # Try
   C:\full\path\to\msp.ps1
   ```

## MSP Lite Issues

### Session Won't Start

**Problem**: "Failed to start session" or session hangs

**Diagnosis**:
```powershell
# Check for existing session
Get-Content .\.msp-lite\current-session.json -ErrorAction SilentlyContinue

# Check permissions
Test-Path .\.msp-lite -PathType Container
```

**Solutions**:
1. Clear stuck session:
   ```powershell
   Remove-Item .\.msp-lite\current-session.json -Force
   ```

2. Reset MSP Lite state:
   ```powershell
   Remove-Item .\.msp-lite -Recurse -Force
   .\msp-lite.ps1 start
   ```

### Updates Not Saving

**Problem**: Updates don't appear in session or context

**Diagnosis**:
```powershell
# Check if file is being written
Get-Content .\.msp-lite\current-session.json | ConvertFrom-Json | Select -ExpandProperty updates
```

**Solution**:
- Ensure the `.msp-lite` directory has write permissions
- Check disk space
- Try running PowerShell as Administrator

### Context Export Empty

**Problem**: `msp-lite context` returns empty or partial data

**Solution**:
1. Ensure you have an active session with updates
2. Try explicit format:
   ```powershell
   .\msp-lite.ps1 context ai
   ```
3. Check session file integrity:
   ```powershell
   $session = Get-Content .\.msp-lite\current-session.json | ConvertFrom-Json
   $session | ConvertTo-Json -Depth 10
   ```

## MSP Standard Issues

### Configuration Not Loading

**Problem**: "Configuration file not found" or settings not applied

**Solution**:
1. Create config from example:
   ```powershell
   Copy-Item .\config\msp-config.example.json .\config\msp-config.json
   ```

2. Validate JSON syntax:
   ```powershell
   $config = Get-Content .\config\msp-config.json -Raw
   try { $config | ConvertFrom-Json } catch { Write-Error $_ }
   ```

3. Check config location:
   ```powershell
   .\msp.ps1 config show
   ```

### Module Loading Errors

**Problem**: "Cannot find module" or "Command not recognized"

**Solution**:
1. Verify file structure:
   ```powershell
   Test-Path .\scripts\core\msp-core.ps1
   Test-Path .\scripts\integrations
   ```

2. Re-download or reinstall MSP Standard

3. Check module paths:
   ```powershell
   $env:PSModulePath -split ';'
   ```

### Integration Not Detected

**Problem**: Neo4j/Obsidian/Linear showing as "not configured"

**Solution**:
1. Check environment variables:
   ```powershell
   # Neo4j
   $env:NEO4J_HOME
   $env:NEO4J_URI
   
   # Obsidian
   $env:OBSIDIAN_VAULT_PATH
   
   # Linear
   $env:LINEAR_API_KEY
   ```

2. Run integration check:
   ```powershell
   .\msp.ps1 check all
   ```

3. Manually configure in `msp-config.json`

## Integration Issues

### Neo4j Connection Failed

**Problem**: Cannot connect to Neo4j database

**Diagnosis**:
```powershell
# Test Neo4j is running
Test-NetConnection localhost -Port 7687

# Check Neo4j Browser
Start-Process "http://localhost:7474"
```

**Solutions**:
1. Start Neo4j:
   ```powershell
   # If using Neo4j Desktop, start from the app
   # If using Docker:
   docker start neo4j
   ```

2. Verify credentials in config

3. Check Neo4j logs for errors

### Obsidian Sync Not Working

**Problem**: Files not appearing in Obsidian vault

**Solution**:
1. Verify vault path:
   ```powershell
   Test-Path $env:OBSIDIAN_VAULT_PATH
   ```

2. Check file permissions

3. Enable file sync in Obsidian settings

4. Try manual file creation:
   ```powershell
   "Test" | Out-File "$env:OBSIDIAN_VAULT_PATH\test.md"
   ```

### Linear API Errors

**Problem**: "Unauthorized" or "API request failed"

**Solution**:
1. Verify API key is valid
2. Check Linear workspace permissions
3. Test with Linear CLI:
   ```powershell
   .\msp.ps1 check linear --verbose
   ```
4. Ensure MCP tools are enabled in Claude

## Performance Issues

### Slow Startup

**Problem**: MSP takes too long to start

**Diagnosis**:
```powershell
Measure-Command { .\msp.ps1 help }
```

**Solutions**:
1. Use MSP Lite for faster startup
2. Disable unused integrations in config
3. Check antivirus isn't scanning MSP files
4. Pre-load modules in PowerShell profile

### High Memory Usage

**Problem**: PowerShell consuming excessive memory

**Solution**:
1. Close and restart PowerShell session
2. Limit session history size:
   ```powershell
   $MaximumHistoryCount = 1000
   ```
3. Use `msp clean` to remove old sessions

## Data Recovery

### Recover Lost Session

**Problem**: Session crashed or wasn't properly ended

**Steps**:
1. List all sessions:
   ```powershell
   .\msp.ps1 sessions
   ```

2. Find orphaned session:
   ```powershell
   .\msp.ps1 recover --list
   ```

3. Recover specific session:
   ```powershell
   .\msp.ps1 recover [session-id]
   ```

### Restore from Backup

MSP automatically backs up sessions. To restore:

```powershell
# Find backups
Get-ChildItem .\.msp\backup\*.json | Sort-Object LastWriteTime -Descending

# Restore specific backup
Copy-Item .\.msp\backup\[filename] .\.msp\current-session.json
```

### Export All Data

To export all MSP data for backup or migration:

```powershell
# Export all sessions
.\msp.ps1 export --all --format json --output msp-backup.json

# Export specific date range
.\msp.ps1 export --from "2024-01-01" --to "2024-12-31"
```

## Getting Help

### Debug Mode

Enable debug output for troubleshooting:

```powershell
# MSP Lite
$env:MSP_DEBUG = "true"
.\msp-lite.ps1 start

# MSP Standard
.\msp.ps1 --debug start
```

### Validation Tools

Run built-in validation:

```powershell
# Check system health
.\msp.ps1 validate

# Detailed diagnostics
.\msp.ps1 diagnose --verbose
```

### Community Support

1. **GitHub Issues**: [github.com/your-username/msp/issues](https://github.com/your-username/msp/issues)
   - Search existing issues first
   - Include version (`msp version`)
   - Provide error messages
   - Share minimal reproduction steps

2. **Discussions**: [github.com/your-username/msp/discussions](https://github.com/your-username/msp/discussions)
   - Ask questions
   - Share tips
   - Request features

3. **Documentation**: [sessionprotocol.dev/](https://sessionprotocol.dev/)
   - Getting started guides
   - API reference
   - Video tutorials

### Diagnostic Information

When reporting issues, include:

```powershell
# Generate diagnostic report
.\msp.ps1 diagnose > msp-diagnostic.txt

# Or manually collect:
$PSVersionTable | Out-String
.\msp.ps1 version
.\msp.ps1 config show
.\msp.ps1 check all
```

### Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| MSP001 | Session already active | End current session first |
| MSP002 | No active session | Start a session |
| MSP003 | Configuration invalid | Check config syntax |
| MSP004 | Integration failed | Check integration settings |
| MSP005 | State corrupted | Run recovery tools |

### Emergency Recovery

If MSP is completely broken:

1. **Safe Mode**:
   ```powershell
   .\msp.ps1 --safe-mode start
   ```

2. **Reset Everything**:
   ```powershell
   # Backup first!
   Copy-Item .\.msp .\.msp-backup -Recurse
   
   # Then reset
   Remove-Item .\.msp -Recurse -Force
   .\msp.ps1 init
   ```

3. **Manual State Edit**:
   ```powershell
   # Edit session file directly
   $session = Get-Content .\.msp\current-session.json | ConvertFrom-Json
   $session.status = "completed"
   $session | ConvertTo-Json -Depth 10 | Set-Content .\.msp\current-session.json
   ```

---

Remember: MSP is designed to be resilient. Most issues can be resolved by:
1. Checking your PowerShell version
2. Verifying file permissions
3. Running validation tools
4. Using recovery commands

