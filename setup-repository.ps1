<#
.SYNOPSIS
    Sets up the MSP (Mandatory Session Protocol) repository structure
.DESCRIPTION
    Creates the complete directory structure and placeholder files for the MSP repository
    Run this script in the root directory where you want to create the MSP repository
#>

param(
    [string]$RepositoryPath = $PWD.Path,
    [switch]$CreateGitRepo = $true
)

Write-Host "🚀 Setting up MSP Repository Structure" -ForegroundColor Cyan
Write-Host "Repository Path: $RepositoryPath" -ForegroundColor Yellow

# Create directory structure
$directories = @(
    # Lite version
    "lite",
    "lite/examples",
    
    # Standard version
    "standard",
    "standard/scripts/core",
    "standard/scripts/integrations/neo4j",
    "standard/scripts/integrations/obsidian",
    "standard/scripts/integrations/linear",
    "standard/scripts/utilities",
    "standard/config",
    "standard/docker",
    
    # Advanced version
    "advanced",
    "advanced/team",
    "advanced/enterprise/compliance",
    "advanced/enterprise/sso-integration",
    "advanced/enterprise/audit-logging",
    "advanced/plugins/example-plugins",
    "advanced/integrations/jira",
    "advanced/integrations/slack",
    "advanced/integrations/gitlab",
    
    # Documentation
    "docs/concepts",
    "docs/guides",
    "docs/api",
    
    # Examples
    "examples/solo-developer",
    "examples/small-team",
    "examples/enterprise",
    
    # Tests
    "tests/lite",
    "tests/standard",
    "tests/integration"
)

foreach ($dir in $directories) {
    $path = Join-Path $RepositoryPath $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "✓ Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "- Exists: $dir" -ForegroundColor Gray
    }
}

# Create root files
$rootFiles = @{
    "README.md" = "# MSP - Mandatory Session Protocol"
    "LICENSE" = "MIT License"
    ".gitignore" = @"
# MSP Specific
.msp/
state/
*.session.json
msp-config.json
!msp-config.example.json

# PowerShell
*.ps1.bak

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp

# Dependencies
node_modules/
*.dll

# Build
dist/
build/
out/
"@
    "CONTRIBUTING.md" = "# Contributing to MSP"
    "CHANGELOG.md" = "# Changelog"
}

foreach ($file in $rootFiles.Keys) {
    $path = Join-Path $RepositoryPath $file
    if (-not (Test-Path $path)) {
        $rootFiles[$file] | Out-File -FilePath $path -Encoding UTF8 -NoNewline
        Write-Host "✓ Created: $file" -ForegroundColor Green
    }
}

# Initialize Git repository
if ($CreateGitRepo -and -not (Test-Path (Join-Path $RepositoryPath ".git"))) {
    Push-Location $RepositoryPath
    git init
    git add .
    git commit -m "Initial MSP repository structure"
    Pop-Location
    Write-Host "`n✓ Git repository initialized" -ForegroundColor Green
}

Write-Host "`n✅ MSP Repository structure created successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. cd $RepositoryPath" -ForegroundColor White
Write-Host "2. Review and customize the generated files" -ForegroundColor White
Write-Host "3. Add your remote: git remote add origin <your-repo-url>" -ForegroundColor White
Write-Host "4. Push to GitHub: git push -u origin main" -ForegroundColor White
