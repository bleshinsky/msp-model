# MSP Integration API

Guide for extending MSP with custom integrations and plugins.

## Architecture Overview

MSP uses a modular architecture that allows easy integration with external tools and services.

```
MSP Core
├── Session Manager
├── State Manager
├── Query Generator
└── Integration Layer
    ├── Neo4j Adapter
    ├── Obsidian Adapter
    ├── Linear Adapter
    └── [Your Custom Adapter]
```

## Creating a Custom Integration

### 1. Integration Structure

Create your integration in `scripts/integrations/your-tool/`:

```
your-tool/
├── your-tool-integration.ps1  # Main integration module
├── setup-your-tool.ps1         # Setup/configuration script
├── README.md                   # Integration documentation
└── config.example.json         # Example configuration
```

### 2. Integration Module Template

```powershell
# your-tool-integration.ps1

<#
.SYNOPSIS
    MSP Integration for YourTool
.DESCRIPTION
    Provides YourTool integration for MSP sessions
#>

# Integration configuration
$script:YourToolConfig = @{
    apiUrl = $env:YOURTOOL_API_URL ?? "https://api.yourtool.com"
    apiKey = $env:YOURTOOL_API_KEY
    enabled = $true
}

function Initialize-YourToolIntegration {
    <#
    .SYNOPSIS
        Initializes YourTool integration
    .DESCRIPTION
        Called during MSP startup to prepare integration
    #>
    param(
        [hashtable]$Config = @{}
    )
    
    # Merge provided config with defaults
    foreach ($key in $Config.Keys) {
        $script:YourToolConfig[$key] = $Config[$key]
    }
    
    # Validate configuration
    if (-not $script:YourToolConfig.apiKey) {
        Write-Warning "YourTool API key not configured"
        $script:YourToolConfig.enabled = $false
        return $false
    }
    
    # Test connection
    try {
        # Your connection test here
        return $true
    }
    catch {
        Write-Warning "YourTool connection failed: $_"
        return $false
    }
}

function New-YourToolSession {
    <#
    .SYNOPSIS
        Creates a new session in YourTool
    .DESCRIPTION
        Called when MSP session starts
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Session
    )
    
    if (-not $script:YourToolConfig.enabled) { return }
    
    # Format data for YourTool
    $payload = @{
        name = "MSP Session $($Session.id)"
        startTime = $Session.startTime
        project = $Session.project
        metadata = @{
            mspVersion = "1.0.0"
            user = $Session.user
        }
    }
    
    # Return formatted data (MSP will handle the actual API call if needed)
    return @{
        action = "create_session"
        endpoint = "/api/sessions"
        method = "POST"
        payload = $payload
    }
}

function Update-YourToolProgress {
    <#
    .SYNOPSIS
        Updates progress in YourTool
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Update,
        
        [Parameter(Mandatory)]
        [string]$SessionId
    )
    
    if (-not $script:YourToolConfig.enabled) { return }
    
    # Format update for YourTool
    return @{
        action = "update_progress"
        endpoint = "/api/sessions/$SessionId/progress"
        method = "PUT"
        payload = @{
            progress = $Update.progress
            message = $Update.description
            timestamp = $Update.timestamp
        }
    }
}

function Export-YourToolContext {
    <#
    .SYNOPSIS
        Exports session context in YourTool format
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Session
    )
    
    # Format session data for YourTool's expected format
    $export = @{
        version = "1.0"
        session = @{
            id = $Session.id
            duration = $Session.duration
            progress = @{
                start = $Session.startProgress
                end = $Session.endProgress
            }
        }
        updates = $Session.updates | ForEach-Object {
            @{
                time = $_.timestamp
                text = $_.description
                progress = $_.progress
            }
        }
    }
    
    return $export | ConvertTo-Json -Depth 10
}

# Export all public functions
Export-ModuleMember -Function Initialize-YourToolIntegration,
                              New-YourToolSession,
                              Update-YourToolProgress,
                              Export-YourToolContext
```

### 3. Hook Points

MSP calls integration functions at these points:

| Hook | Function | Purpose |
|------|----------|---------|
| Startup | `Initialize-*Integration` | Validate config, test connection |
| Session Start | `New-*Session` | Create session in external tool |
| Update | `Update-*Progress` | Sync progress updates |
| Decision | `Add-*Decision` | Record decisions |
| Entity | `Add-*Entity` | Track created entities |
| Session End | `Close-*Session` | Finalize session |
| Export | `Export-*Context` | Export in tool's format |

### 4. Registration

Register your integration in MSP config:

```json
{
  "integrations": {
    "yourTool": {
      "enabled": true,
      "module": "your-tool-integration.ps1",
      "config": {
        "apiUrl": "https://api.yourtool.com",
        "projectId": "12345"
      }
    }
  }
}
```

### 5. Error Handling

Always handle errors gracefully:

```powershell
function Update-YourToolProgress {
    param($Update, $SessionId)
    
    try {
        # Your integration logic
    }
    catch {
        # Log error but don't break MSP flow
        Write-MSPLog "YourTool update failed: $_" -Level Warning
        
        # Optionally queue for retry
        Add-MSPRetryQueue -Integration "YourTool" -Action "UpdateProgress" -Data $Update
    }
}
```

## Query Generation Pattern

Following the ATAI pattern, integrations should generate queries/commands rather than execute them:

```powershell
function New-YourToolQuery {
    param($Action, $Data)
    
    switch ($Action) {
        "CreateTask" {
            return @"
POST /api/tasks
{
  "title": "$($Data.title)",
  "description": "$($Data.description)",
  "assignee": "$($Data.user)"
}
"@
        }
    }
}
```

## Testing Your Integration

Create test script `test-your-tool-integration.ps1`:

```powershell
# Test initialization
$config = @{
    apiKey = "test-key"
    apiUrl = "https://test.api.com"
}
$initialized = Initialize-YourToolIntegration -Config $config
Assert-True $initialized "Integration should initialize"

# Test session creation
$session = @{
    id = "test-001"
    project = "TestProject"
    user = "testuser"
}
$result = New-YourToolSession -Session $session
Assert-NotNull $result "Should return session data"
Assert-Equals $result.method "POST" "Should use POST method"

# Test progress update
$update = @{
    description = "Test update"
    progress = 50
    timestamp = Get-Date
}
$result = Update-YourToolProgress -Update $update -SessionId "test-001"
Assert-NotNull $result.payload "Should have payload"
```

## Best Practices

### 1. **Configuration**
- Support environment variables
- Provide sensible defaults
- Validate all required settings
- Include example configuration

### 2. **Error Handling**
- Never crash MSP core
- Log warnings for non-critical failures
- Queue failed operations for retry
- Provide clear error messages

### 3. **Performance**
- Make operations async when possible
- Cache frequently used data
- Batch API calls
- Respect rate limits

### 4. **Security**
- Never log sensitive data
- Use secure credential storage
- Validate all inputs
- Follow principle of least privilege

### 5. **Documentation**
- Include README with setup instructions
- Document all configuration options
- Provide usage examples
- List prerequisites

## Example Integrations

### Slack Notifications

```powershell
function Send-SlackSessionSummary {
    param($Session)
    
    $blocks = @(
        @{
            type = "header"
            text = @{
                type = "plain_text"
                text = "MSP Session Complete"
            }
        }
        @{
            type = "section"
            fields = @(
                @{
                    type = "mrkdwn"
                    text = "*Duration:*\n$($Session.duration) hours"
                }
                @{
                    type = "mrkdwn"
                    text = "*Progress:*\n$($Session.startProgress)% → $($Session.endProgress)%"
                }
            )
        }
    )
    
    return @{
        webhook = $env:SLACK_WEBHOOK_URL
        payload = @{
            blocks = $blocks
            text = "Session $($Session.id) complete"
        }
    }
}
```

### Jira Integration

```powershell
function Update-JiraIssue {
    param($Session, $IssueKey)
    
    $comment = @"
MSP Session Update
------------------
Duration: $($Session.duration) hours
Progress: $($Session.endProgress)%

Updates:
$(($Session.updates | ForEach-Object { "- $($_.description)" }) -join "`n")

Decisions:
$(($Session.decisions | ForEach-Object { "- $($_.content)" }) -join "`n")
"@
    
    return @{
        action = "add_comment"
        endpoint = "/rest/api/2/issue/$IssueKey/comment"
        payload = @{
            body = $comment
        }
    }
}
```

## Publishing Your Integration

1. Create a GitHub repository
2. Include installation script
3. Add to MSP integration registry
4. Submit PR to main MSP repo (optional)
5. Share with the community

## Support

- Integration Development Guide: [Link]
- Example Integrations: `examples/integrations/`
- Community Forum: [Discord #integrations]
- Office Hours: Thursdays 2 PM EST
