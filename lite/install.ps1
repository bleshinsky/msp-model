#Requires -Version 7.0
<#
.SYNOPSIS
    MSP Lite installer - one-line installation script
.DESCRIPTION
    Downloads and installs MSP Lite with proper PATH configuration
.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/yourusername/msp/main/lite/install.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

Write-Host "🚀 Installing MSP Lite..." -ForegroundColor Cyan

# Determine installation directory
$installDir = if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
    Join-Path $env:LOCALAPPDATA 'MSP'
} else {
    Join-Path $HOME '.local' 'bin'
}

# Create directory if it doesn't exist
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "✓ Created installation directory: $installDir" -ForegroundColor Green
}

# Download MSP Lite
$scriptUrl = "https://raw.githubusercontent.com/yourusername/msp/main/lite/msp-lite.ps1"
$scriptPath = Join-Path $installDir "msp-lite.ps1"

try {
    Write-Host "📥 Downloading MSP Lite..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing
    Write-Host "✓ Downloaded MSP Lite" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download MSP Lite: $_" -ForegroundColor Red
    exit 1
}

# Create wrapper script for easier execution
$wrapperContent = @"
#!/usr/bin/env pwsh
# MSP Lite wrapper script
& '$scriptPath' `@args
"@

if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
    # Windows: Create batch file wrapper
    $wrapperPath = Join-Path $installDir "msp-lite.cmd"
    @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$scriptPath" %*
"@ | Out-File $wrapperPath -Encoding ASCII
    
    # Add to PATH if not already there
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$installDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
        Write-Host "✓ Added to PATH (restart terminal to use 'msp-lite' command)" -ForegroundColor Green
    }
} else {
    # Mac/Linux: Create shell wrapper
    $wrapperPath = Join-Path $installDir "msp-lite"
    $wrapperContent | Out-File $wrapperPath -Encoding UTF8
    chmod +x $wrapperPath
    chmod +x $scriptPath
    
    # Add to PATH via profile if needed
    $profileAddition = "`n# MSP Lite`nexport PATH=`"$installDir:`$PATH`"`n"
    
    $profiles = @(
        "~/.bashrc",
        "~/.zshrc",
        "~/.profile"
    )
    
    $profileUpdated = $false
    foreach ($profile in $profiles) {
        $profilePath = $ExecutionContext.InvokeCommand.ExpandString($profile)
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            if ($content -notlike "*MSP Lite*") {
                Add-Content $profilePath $profileAddition
                $profileUpdated = $true
                Write-Host "✓ Added to $profile" -ForegroundColor Green
            }
        }
    }
    
    if ($profileUpdated) {
        Write-Host "✓ Added to PATH (run 'source ~/.bashrc' or restart terminal)" -ForegroundColor Green
    }
}

# Create initial state directory
$stateDir = Join-Path $HOME '.msp-lite'
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $stateDir 'archive') -Force | Out-Null
    Write-Host "✓ Created state directory: $stateDir" -ForegroundColor Green
}

# Test installation
try {
    & $scriptPath help | Out-Null
    Write-Host "`n✅ MSP Lite installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Installation completed but test failed: $_" -ForegroundColor Yellow
}

# Show next steps
Write-Host "`n📖 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Restart your terminal or run:" -ForegroundColor White
if ($IsWindows -or $PSVersionTable.Platform -eq 'Win32NT') {
    Write-Host "   `$env:Path = [System.Environment]::GetEnvironmentVariable('Path','User')" -ForegroundColor Gray
} else {
    Write-Host "   source ~/.bashrc" -ForegroundColor Gray
}
Write-Host "`n2. Start tracking:" -ForegroundColor White
Write-Host "   msp-lite start" -ForegroundColor Gray
Write-Host "   msp-lite update 'Working on MSP installation' 10" -ForegroundColor Gray
Write-Host "   msp-lite end" -ForegroundColor Gray
Write-Host "`n3. Get help:" -ForegroundColor White
Write-Host "   msp-lite help" -ForegroundColor Gray

Write-Host "`n🚀 Happy tracking with MSP Lite!" -ForegroundColor Magenta
