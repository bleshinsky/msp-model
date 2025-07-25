# MSP Git Integration Script
# Generates commit messages from session data

param(
    [switch]$Commit,
    [switch]$Push,
    [string]$Type = "feat",  # feat, fix, docs, style, refactor, test, chore
    [string]$Scope = "msp"
)

Write-Host "`nMSP Git Integration" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

# Check for active session
$sessionFile = "$env:TEMP\msp-session-$(Get-Date -Format 'yyyy-MM-dd').json"
if (-not (Test-Path $sessionFile)) {
    Write-Host "`nERROR: No active session found." -ForegroundColor Red
    Write-Host "Start a session first with '.\msp.ps1 start'" -ForegroundColor Yellow
    return
}

# Load session data
$sessionData = Get-Content $sessionFile | ConvertFrom-Json

# Check if we have updates
if ($sessionData.Updates.Count -eq 0) {
    Write-Host "`nNo updates in current session to commit." -ForegroundColor Yellow
    return
}

# Generate commit message
$primaryUpdate = $sessionData.Updates | Select-Object -Last 1
$commitTitle = "$Type($Scope): $($primaryUpdate.Notes)"

# Limit title length
if ($commitTitle.Length -gt 72) {
    $commitTitle = $commitTitle.Substring(0, 69) + "..."
}

$commitBody = ""
if ($sessionData.Updates.Count -gt 1) {
    $commitBody = "`n`nSession updates:"
    foreach ($update in $sessionData.Updates) {
        $commitBody += "`n- $($update.Notes)"
        if ($update.Progress) {
            $commitBody += " ($($update.Progress)%)"
        }
    }
}

# Add metadata
$commitBody += "`n`nSession ID: $($sessionData.SessionId)"
if ($sessionData.LinearIssueId) {
    $commitBody += "`nLinear: $($sessionData.LinearIssueId)"
}

$fullCommitMessage = $commitTitle + $commitBody

# Show the commit message
Write-Host "`nGenerated commit message:" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow
Write-Host $fullCommitMessage -ForegroundColor Gray
Write-Host "========================" -ForegroundColor Yellow

# Check git status
Write-Host "`nGit status:" -ForegroundColor Cyan
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host $gitStatus -ForegroundColor Gray
} else {
    Write-Host "Working tree clean - no changes to commit" -ForegroundColor Yellow
}

if ($Commit) {
    if (-not $gitStatus) {
        Write-Host "`n[!] No changes to commit" -ForegroundColor Yellow
        Write-Host "Make some changes to your code first!" -ForegroundColor Gray
        return
    }
    
    Write-Host "`nCommitting changes..." -ForegroundColor Yellow
    
    # Stage all changes (you might want to be more selective)
    git add -A
    
    # Create commit
    git commit -m $commitTitle -m $commitBody.Trim()
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[+] Commit created successfully" -ForegroundColor Green
        
        if ($Push) {
            Write-Host "`nPushing to remote..." -ForegroundColor Yellow
            git push
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[+] Pushed successfully" -ForegroundColor Green
            } else {
                Write-Host "[!] Push failed" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "[!] Commit failed" -ForegroundColor Red
    }
} else {
    Write-Host "`nTo commit these changes, run:" -ForegroundColor Yellow
    Write-Host "  .\msp.ps1 git commit" -ForegroundColor White
    Write-Host "  .\msp.ps1 git commit push" -ForegroundColor White
    
    Write-Host "`nOr copy the commit message to clipboard:" -ForegroundColor Yellow
    $fullCommitMessage | Set-Clipboard
    Write-Host "[+] Commit message copied to clipboard" -ForegroundColor Green
}
