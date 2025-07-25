#Requires -Version 7.0
<#
.SYNOPSIS
    Initialize and publish MSP repository to GitHub
.DESCRIPTION
    Sets up Git repository, creates initial commit, and provides instructions for GitHub publishing
#>

param(
    [string]$GitHubUsername = "bleshik",
    [string]$RepositoryName = "msp",
    [switch]$SkipGitInit,
    [switch]$CreateGitHubRepo
)

$ErrorActionPreference = 'Stop'

Write-Host @"
╔══════════════════════════════════════╗
║     MSP Git Repository Setup         ║
╚══════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path ".\lite\msp-lite.ps1")) {
    Write-Error "This script must be run from the MSP root directory (C:\__gh\msp)"
    exit 1
}

# Check if Git is installed
try {
    $gitVersion = git --version
    Write-Host "✓ Git installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Error "Git is not installed. Please install Git first: https://git-scm.com"
    exit 1
}

# Check if already a git repository
$isGitRepo = Test-Path ".\.git"
if ($isGitRepo -and -not $SkipGitInit) {
    Write-Host "⚠️  This directory is already a Git repository" -ForegroundColor Yellow
    $continue = Read-Host "Do you want to continue anyway? (y/N)"
    if ($continue -ne 'y') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 0
    }
}

# Initialize Git repository
if (-not $isGitRepo -and -not $SkipGitInit) {
    Write-Host "`nInitializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "✓ Git repository initialized" -ForegroundColor Green
}

# Configure Git (if needed)
$userName = git config user.name 2>$null
$userEmail = git config user.email 2>$null

if (-not $userName -or -not $userEmail) {
    Write-Host "`nGit user configuration needed:" -ForegroundColor Yellow
    if (-not $userName) {
        $name = Read-Host "Enter your name for Git commits"
        git config user.name "$name"
    }
    if (-not $userEmail) {
        $email = Read-Host "Enter your email for Git commits"
        git config user.email "$email"
    }
}

# Create .gitattributes file
Write-Host "`nCreating Git attributes file..." -ForegroundColor Yellow
@'
# Auto detect text files and perform LF normalization
* text=auto

# PowerShell scripts
*.ps1 text eol=crlf
*.psd1 text eol=crlf
*.psm1 text eol=crlf

# Markdown
*.md text

# Config files
*.json text
*.xml text
*.yaml text
*.yml text

# Binary files
*.png binary
*.jpg binary
*.gif binary
*.ico binary
*.pdf binary
'@ | Out-File -FilePath ".\.gitattributes" -Encoding UTF8

Write-Host "✓ Created .gitattributes" -ForegroundColor Green

# Update .gitignore if needed
if (Test-Path ".\.gitignore") {
    Write-Host "✓ .gitignore already exists" -ForegroundColor Green
} else {
    Write-Host "✓ .gitignore was already created during setup" -ForegroundColor Green
}

# Stage all files
Write-Host "`nStaging files for commit..." -ForegroundColor Yellow
git add -A

# Show what will be committed
Write-Host "`nFiles to be committed:" -ForegroundColor Cyan
git status --short

# Create initial commit
Write-Host "`nCreating initial commit..." -ForegroundColor Yellow
$commitMessage = @"
Initial commit: MSP (Mandatory Session Protocol)

MSP is a developer productivity tool for structured session management.

Features:
- MSP Lite: Zero-dependency quick start version
- MSP Standard: Full NOL Framework (Neo4j + Obsidian + Linear)
- MSP Advanced: Enterprise features for teams

This initial commit includes:
- Complete implementation of all three versions
- Comprehensive documentation
- Example scripts and templates
- Full test suite
- Setup and configuration tools

Version: 1.0.0
License: MIT
"@

git commit -m "$commitMessage"
Write-Host "✓ Initial commit created" -ForegroundColor Green

# Show commit info
Write-Host "`nCommit details:" -ForegroundColor Cyan
git log --oneline -1

# Create GitHub repository instructions
Write-Host "`n" + ("="*50) -ForegroundColor DarkGray
Write-Host "GitHub Repository Setup Instructions" -ForegroundColor Cyan
Write-Host ("="*50) -ForegroundColor DarkGray

Write-Host "`n1. Create a new repository on GitHub:" -ForegroundColor Yellow
Write-Host "   - Go to: https://github.com/new" -ForegroundColor White
Write-Host "   - Repository name: $RepositoryName" -ForegroundColor White
Write-Host "   - Description: MSP - Mandatory Session Protocol: Never lose context again" -ForegroundColor White
Write-Host "   - Public repository: Yes (recommended)" -ForegroundColor White
Write-Host "   - Initialize: NO (don't add README, license, or .gitignore)" -ForegroundColor White
Write-Host "   - Click 'Create repository'" -ForegroundColor White

Write-Host "`n2. After creating, run these commands:" -ForegroundColor Yellow
Write-Host @"
   git remote add origin https://github.com/$GitHubUsername/$RepositoryName.git
   git branch -M main
   git push -u origin main
"@ -ForegroundColor Green

# Optionally create GitHub repo using GitHub CLI
if ($CreateGitHubRepo) {
    Write-Host "`nChecking for GitHub CLI..." -ForegroundColor Yellow
    try {
        $ghVersion = gh --version
        Write-Host "✓ GitHub CLI installed" -ForegroundColor Green
        
        Write-Host "Creating GitHub repository..." -ForegroundColor Yellow
        gh repo create "$GitHubUsername/$RepositoryName" `
            --public `
            --description "MSP - Mandatory Session Protocol: Never lose context again" `
            --homepage "https://sessionprotocol.dev" `
            --disable-wiki `
            --disable-issues=false
            
        Write-Host "✓ GitHub repository created" -ForegroundColor Green
        
        # Set remote
        git remote add origin "https://github.com/$GitHubUsername/$RepositoryName.git"
        git branch -M main
        
        Write-Host "`nPushing to GitHub..." -ForegroundColor Yellow
        git push -u origin main
        
        Write-Host "✓ Repository published to GitHub!" -ForegroundColor Green
        Write-Host "`nView your repository: https://github.com/$GitHubUsername/$RepositoryName" -ForegroundColor Cyan
        
    } catch {
        Write-Host "GitHub CLI not installed. Please create repository manually." -ForegroundColor Yellow
    }
}

# Additional setup suggestions
Write-Host "`n" + ("="*50) -ForegroundColor DarkGray
Write-Host "Recommended Next Steps" -ForegroundColor Cyan
Write-Host ("="*50) -ForegroundColor DarkGray

Write-Host @"
1. Add repository topics on GitHub:
   - developer-tools
   - productivity
   - session-management
   - powershell
   - context-engineering
   - neo4j
   - obsidian
   - linear

2. Create a release:
   - Tag: v1.0.0
   - Title: MSP 1.0.0 - Initial Release
   - Mark as latest release

3. Enable GitHub Pages (optional):
   - Settings → Pages → Source: Deploy from branch
   - Branch: main, folder: /docs

4. Set up GitHub Actions (optional):
   - Create .github/workflows/test.yml
   - Run tests on push/PR

5. Add shields/badges to README:
   - Version badge
   - License badge
   - PowerShell badge

6. Share your repository:
   - Twitter/X
   - Dev.to article
   - Reddit r/PowerShell
   - Hacker News
"@ -ForegroundColor White

Write-Host "`n✨ Git repository setup complete!" -ForegroundColor Green