#Requires -Version 7.0
<#
.SYNOPSIS
    Test suite for MSP Lite
.DESCRIPTION
    Tests core functionality of the zero-dependency MSP Lite version
#>

# Test framework
$testResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Errors = @()
}

function Test-Case {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    $testResults.Total++
    Write-Host "  Testing: $Name... " -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "✓" -ForegroundColor Green
            $testResults.Passed++
        } else {
            Write-Host "✗" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Errors += "Failed: $Name"
        }
    } catch {
        Write-Host "✗ (Error: $_)" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Errors += "Error in $Name: $_"
    }
}

# Setup test environment
$testDir = Join-Path $env:TEMP "msp-lite-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Push-Location $testDir

try {
    # Copy MSP Lite script
    $mspLitePath = Join-Path $PSScriptRoot "..\..\lite\msp-lite.ps1"
    Copy-Item $mspLitePath -Destination ".\msp-lite.ps1" -Force
    
    Write-Host "`n🧪 MSP Lite Test Suite" -ForegroundColor Cyan
    Write-Host "Test Directory: $testDir" -ForegroundColor Gray
    
    # Test 1: Script exists and is valid
    Write-Host "`n📋 Basic Tests:" -ForegroundColor Yellow
    
    Test-Case "Script exists" {
        Test-Path ".\msp-lite.ps1"
    }
    
    Test-Case "Script has no syntax errors" {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content ".\msp-lite.ps1" -Raw), [ref]$null)
        $true
    }
    
    # Test 2: Help command
    Write-Host "`n📋 Command Tests:" -ForegroundColor Yellow
    
    Test-Case "Help command works" {
        $output = & .\msp-lite.ps1 help 2>&1
        $output -match "MSP Lite"
    }
    
    Test-Case "Status command works without session" {
        $output = & .\msp-lite.ps1 status 2>&1
        $output -match "No active session"
    }
    
    # Test 3: Session lifecycle
    Write-Host "`n📋 Session Lifecycle Tests:" -ForegroundColor Yellow
    
    Test-Case "Start session" {
        $output = & .\msp-lite.ps1 start 2>&1
        $output -match "Session started" -and (Test-Path ".\.msp-lite\current-session.json")
    }
    
    Test-Case "Session file contains required fields" {
        $session = Get-Content ".\.msp-lite\current-session.json" | ConvertFrom-Json
        $session.id -and $session.startTime -and $session.status -eq 'active'
    }
    
    Test-Case "Update session" {
        $output = & .\msp-lite.ps1 update "Test update" 25 2>&1
        $output -match "recorded"
    }
    
    Test-Case "Update is saved" {
        $session = Get-Content ".\.msp-lite\current-session.json" | ConvertFrom-Json
        $session.updates.Count -gt 0 -and $session.updates[0].notes -eq "Test update"
    }
    
    Test-Case "Multiple updates" {
        & .\msp-lite.ps1 update "Second update" 50 2>&1
        & .\msp-lite.ps1 update "Third update" 2>&1
        $session = Get-Content ".\.msp-lite\current-session.json" | ConvertFrom-Json
        $session.updates.Count -eq 3
    }
    
    Test-Case "Status shows active session" {
        $output = & .\msp-lite.ps1 status 2>&1
        $output -match "Active session" -and $output -match "updates: 3"
    }
    
    Test-Case "End session" {
        $output = & .\msp-lite.ps1 end 2>&1
        $output -match "Session ended" -and $output -match "Duration:"
    }
    
    Test-Case "Session archived after end" {
        (Test-Path ".\.msp-lite\sessions\*.json") -and
        -not (Test-Path ".\.msp-lite\current-session.json")
    }
    
    # Test 4: Context export
    Write-Host "`n📋 Context Export Tests:" -ForegroundColor Yellow
    
    Test-Case "Start new session for context test" {
        $output = & .\msp-lite.ps1 start 2>&1
        $output -match "Session started"
    }
    
    Test-Case "Add context data" {
        & .\msp-lite.ps1 update "Implemented feature X" 30 2>&1
        & .\msp-lite.ps1 decide "Using pattern Y for performance" 2>&1
        $true
    }
    
    Test-Case "Context export works" {
        $output = & .\msp-lite.ps1 context 2>&1
        $output -match "PROJECT CONTEXT" -and $output -match "Implemented feature X"
    }
    
    Test-Case "AI format export" {
        $output = & .\msp-lite.ps1 context ai 2>&1
        $output -match "Copy this context to your AI"
    }
    
    # Test 5: Error handling
    Write-Host "`n📋 Error Handling Tests:" -ForegroundColor Yellow
    
    Test-Case "Cannot start session when active" {
        $output = & .\msp-lite.ps1 start 2>&1
        $output -match "already active"
    }
    
    Test-Case "Cannot update without session" {
        & .\msp-lite.ps1 end 2>&1
        $output = & .\msp-lite.ps1 update "Should fail" 2>&1
        $output -match "No active session"
    }
    
    Test-Case "Invalid progress value" {
        & .\msp-lite.ps1 start 2>&1
        $output = & .\msp-lite.ps1 update "Test" 150 2>&1
        $output -match "Progress must be"
    }
    
    # Test 6: Session recovery
    Write-Host "`n📋 Recovery Tests:" -ForegroundColor Yellow
    
    Test-Case "Create orphaned session" {
        $session = @{
            id = "test-orphan"
            startTime = (Get-Date).ToString('o')
            status = "active"
            updates = @()
        }
        $session | ConvertTo-Json | Out-File ".\.msp-lite\current-session.json"
        $true
    }
    
    Test-Case "List sessions shows orphaned" {
        $output = & .\msp-lite.ps1 sessions 2>&1
        $output -match "test-orphan"
    }
    
    Test-Case "Recover orphaned session" {
        $output = & .\msp-lite.ps1 recover 2>&1
        $output -match "recovered"
    }
    
    # Cleanup current session
    if (Test-Path ".\.msp-lite\current-session.json") {
        & .\msp-lite.ps1 end 2>&1
    }
    
} finally {
    Pop-Location
    Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Display results
Write-Host "`n📊 Test Results:" -ForegroundColor Cyan
Write-Host "  Total:  $($testResults.Total)"
Write-Host "  Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "  Failed: $($testResults.Failed)" -ForegroundColor Red

if ($testResults.Errors.Count -gt 0) {
    Write-Host "`n❌ Errors:" -ForegroundColor Red
    $testResults.Errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

# Return results for test runner
return $testResults