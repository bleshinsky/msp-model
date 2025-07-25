#Requires -Version 7.0
<#
.SYNOPSIS
    Quick test to verify MSP installation
.DESCRIPTION
    Runs basic tests to ensure MSP is properly installed and working
.EXAMPLE
    .\test-installation.ps1
#>

Write-Host @"
╔══════════════════════════════════════╗
║       MSP Installation Test          ║
║   Verifying your MSP installation    ║
╚══════════════════════════════════════╝
"@ -ForegroundColor Cyan

$results = @{
    PowerShell = $false
    Structure = $false
    Lite = $false
    Standard = $false
    Permissions = $false
}

# Test 1: PowerShell Version
Write-Host "`n1. Checking PowerShell version..." -NoNewline
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Host " ✓" -ForegroundColor Green
    Write-Host "   Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
    $results.PowerShell = $true
} else {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "   ERROR: PowerShell 7.0+ required. Current: $($PSVersionTable.PSVersion)" -ForegroundColor Red
}

# Test 2: File Structure
Write-Host "`n2. Checking MSP file structure..." -NoNewline
$requiredPaths = @(
    ".\lite\msp-lite.ps1",
    ".\standard\msp.ps1",
    ".\docs\README.md",
    ".\examples",
    ".\tests"
)

$missingPaths = $requiredPaths | Where-Object { -not (Test-Path $_) }
if ($missingPaths.Count -eq 0) {
    Write-Host " ✓" -ForegroundColor Green
    Write-Host "   All required files found" -ForegroundColor Gray
    $results.Structure = $true
} else {
    Write-Host " ✗" -ForegroundColor Red
    $missingPaths | ForEach-Object {
        Write-Host "   Missing: $_" -ForegroundColor Red
    }
}

# Test 3: MSP Lite
Write-Host "`n3. Testing MSP Lite..." -NoNewline
try {
    $liteOutput = & .\lite\msp-lite.ps1 help 2>&1 | Out-String
    if ($liteOutput -match "MSP Lite") {
        Write-Host " ✓" -ForegroundColor Green
        Write-Host "   MSP Lite is working" -ForegroundColor Gray
        $results.Lite = $true
    } else {
        throw "Unexpected output"
    }
} catch {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "   ERROR: $_" -ForegroundColor Red
}

# Test 4: MSP Standard
Write-Host "`n4. Testing MSP Standard..." -NoNewline
try {
    $standardOutput = & .\standard\msp.ps1 help 2>&1 | Out-String
    if ($standardOutput -match "MSP.*Standard") {
        Write-Host " ✓" -ForegroundColor Green
        Write-Host "   MSP Standard is working" -ForegroundColor Gray
        $results.Standard = $true
    } else {
        throw "Unexpected output"
    }
} catch {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "   ERROR: $_" -ForegroundColor Red
}

# Test 5: Write Permissions
Write-Host "`n5. Checking write permissions..." -NoNewline
try {
    $testFile = ".\test-write-$(Get-Random).tmp"
    "test" | Out-File $testFile
    Remove-Item $testFile
    Write-Host " ✓" -ForegroundColor Green
    Write-Host "   Can create files in current directory" -ForegroundColor Gray
    $results.Permissions = $true
} catch {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "   ERROR: Cannot write to current directory" -ForegroundColor Red
}

# Optional Integration Checks
Write-Host "`n6. Checking optional integrations:" -ForegroundColor Yellow

# Neo4j
Write-Host "   Neo4j: " -NoNewline
if ($env:NEO4J_HOME -or $env:NEO4J_URI) {
    Write-Host "Configured ✓" -ForegroundColor Green
} else {
    Write-Host "Not configured (optional)" -ForegroundColor Gray
}

# Obsidian
Write-Host "   Obsidian: " -NoNewline
if ($env:OBSIDIAN_VAULT_PATH -and (Test-Path $env:OBSIDIAN_VAULT_PATH)) {
    Write-Host "Configured ✓" -ForegroundColor Green
} else {
    Write-Host "Not configured (optional)" -ForegroundColor Gray
}

# Linear
Write-Host "   Linear: " -NoNewline
if ($env:LINEAR_API_KEY) {
    Write-Host "Configured ✓" -ForegroundColor Green
} else {
    Write-Host "Not configured (optional)" -ForegroundColor Gray
}

# Summary
Write-Host "`n" + ("=" * 40) -ForegroundColor DarkGray
$passedTests = ($results.Values | Where-Object { $_ }).Count
$totalTests = $results.Count

if ($passedTests -eq $totalTests) {
    Write-Host "✅ ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "`nMSP is properly installed and ready to use." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Try MSP Lite:     .\lite\msp-lite.ps1 start" -ForegroundColor White
    Write-Host "  2. Try MSP Standard: .\standard\msp.ps1 start" -ForegroundColor White
    Write-Host "  3. Read the docs:    Get-Content .\README.md" -ForegroundColor White
} else {
    Write-Host "⚠️  SOME TESTS FAILED ($passedTests/$totalTests passed)" -ForegroundColor Yellow
    Write-Host "`nPlease fix the issues above before using MSP." -ForegroundColor Yellow
    Write-Host "See .\docs\guides\troubleshooting.md for help." -ForegroundColor Yellow
}

# Quick functionality test
if ($passedTests -eq $totalTests) {
    Write-Host "`nRunning quick functionality test..." -ForegroundColor Cyan
    
    try {
        # Test MSP Lite session
        Write-Host "  Creating test session... " -NoNewline
        & .\lite\msp-lite.ps1 start *> $null
        Write-Host "✓" -ForegroundColor Green
        
        Write-Host "  Adding update... " -NoNewline
        & .\lite\msp-lite.ps1 update "Installation test" 100 *> $null
        Write-Host "✓" -ForegroundColor Green
        
        Write-Host "  Ending session... " -NoNewline
        & .\lite\msp-lite.ps1 end *> $null
        Write-Host "✓" -ForegroundColor Green
        
        Write-Host "`n🎉 MSP is working perfectly!" -ForegroundColor Green
    } catch {
        Write-Host "✗" -ForegroundColor Red
        Write-Host "  Warning: Basic functionality test failed" -ForegroundColor Yellow
    }
}

Write-Host "`nInstallation test complete.`n" -ForegroundColor Cyan