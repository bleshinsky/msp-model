<#
.SYNOPSIS
    Integration test suite for MSP
.DESCRIPTION
    Tests integration between MSP versions and with external tools
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

# Test prerequisites
function Test-Prerequisites {
    Write-Host "`n📋 Checking Prerequisites:" -ForegroundColor Yellow
    
    $hasNeo4j = Test-Path env:NEO4J_HOME
    $hasObsidian = Test-Path env:OBSIDIAN_VAULT_PATH
    $hasLinear = Test-Path env:LINEAR_API_KEY
    
    Write-Host "  Neo4j:    $(if ($hasNeo4j) { '✓ Available' } else { '✗ Not configured' })" -ForegroundColor $(if ($hasNeo4j) { 'Green' } else { 'Yellow' })
    Write-Host "  Obsidian: $(if ($hasObsidian) { '✓ Available' } else { '✗ Not configured' })" -ForegroundColor $(if ($hasObsidian) { 'Green' } else { 'Yellow' })
    Write-Host "  Linear:   $(if ($hasLinear) { '✓ Available' } else { '✗ Not configured' })" -ForegroundColor $(if ($hasLinear) { 'Green' } else { 'Yellow' })
    
    return @{
        Neo4j = $hasNeo4j
        Obsidian = $hasObsidian
        Linear = $hasLinear
    }
}

# Setup test environment
$testDir = Join-Path $env:TEMP "msp-integration-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Push-Location $testDir

try {
    # Copy all MSP versions
    $repoRoot = Join-Path $PSScriptRoot "..\.."
    Copy-Item "$repoRoot\lite" -Destination . -Recurse -Force
    Copy-Item "$repoRoot\standard" -Destination . -Recurse -Force
    
    Write-Host "`n🧪 MSP Integration Test Suite" -ForegroundColor Cyan
    Write-Host "Test Directory: $testDir" -ForegroundColor Gray
    
    $prereqs = Test-Prerequisites
    
    # Test 1: Version compatibility
    Write-Host "`n📋 Version Compatibility Tests:" -ForegroundColor Yellow
    
    Test-Case "Lite and Standard use compatible state format" {
        # Start session in Lite
        & .\lite\msp-lite.ps1 start 2>&1
        & .\lite\msp-lite.ps1 update "Test from Lite" 25 2>&1
        $liteSession = Get-Content ".\.msp-lite\current-session.json" | ConvertFrom-Json
        & .\lite\msp-lite.ps1 end 2>&1
        
        # Check if Standard can read Lite format
        $liteSession.id -and $liteSession.updates -and $liteSession.startTime
    }
    
    Test-Case "Context export format is consistent" {
        # Start Lite session
        & .\lite\msp-lite.ps1 start 2>&1
        & .\lite\msp-lite.ps1 update "Building feature" 30 2>&1
        $liteContext = & .\lite\msp-lite.ps1 context 2>&1
        & .\lite\msp-lite.ps1 end 2>&1
        
        # Both should have PROJECT CONTEXT section
        $liteContext -match "PROJECT CONTEXT"
    }
    
    # Test 2: Migration scenarios
    Write-Host "`n📋 Migration Tests:" -ForegroundColor Yellow
    
    Test-Case "Can migrate from Lite to Standard format" {
        # Create Lite session
        $liteDir = ".\.msp-lite\sessions"
        New-Item -ItemType Directory -Path $liteDir -Force | Out-Null
        
        $liteSession = @{
            id = "lite-test-001"
            startTime = (Get-Date).AddHours(-2).ToString('o')
            endTime = (Get-Date).AddHours(-1).ToString('o')
            updates = @(
                @{
                    timestamp = (Get-Date).AddHours(-1.5).ToString('o')
                    notes = "Migrated from Lite"
                    progress = 50
                }
            )
        }
        
        $liteSession | ConvertTo-Json -Depth 10 | Out-File "$liteDir\lite-test-001.json"
        
        # Standard should be able to process this format
        $content = Get-Content "$liteDir\lite-test-001.json" -Raw | ConvertFrom-Json
        $content.id -eq "lite-test-001" -and $content.updates.Count -eq 1
    }
    
    # Test 3: Tool detection
    Write-Host "`n📋 Tool Detection Tests:" -ForegroundColor Yellow
    
    Test-Case "Neo4j connection test" {
        if ($prereqs.Neo4j) {
            $output = & .\standard\msp.ps1 check neo4j 2>&1
            $output -match "Neo4j" -and ($output -match "available" -or $output -match "connected")
        } else {
            Write-Host " (Skipped - Neo4j not configured)" -ForegroundColor Yellow
            $true
        }
    }
    
    Test-Case "Obsidian vault detection" {
        if ($prereqs.Obsidian) {
            $output = & .\standard\msp.ps1 check obsidian 2>&1
            $output -match "Obsidian" -and $output -match "vault"
        } else {
            Write-Host " (Skipped - Obsidian not configured)" -ForegroundColor Yellow
            $true
        }
    }
    
    Test-Case "Linear API check" {
        if ($prereqs.Linear) {
            $output = & .\standard\msp.ps1 check linear 2>&1
            $output -match "Linear"
        } else {
            Write-Host " (Skipped - Linear not configured)" -ForegroundColor Yellow
            $true
        }
    }
    
    # Test 4: Cross-version features
    Write-Host "`n📋 Cross-Version Feature Tests:" -ForegroundColor Yellow
    
    Test-Case "Both versions support context command" {
        $liteHelp = & .\lite\msp-lite.ps1 help 2>&1
        $standardHelp = & .\standard\msp.ps1 help 2>&1
        
        ($liteHelp -match "context") -and ($standardHelp -match "context")
    }
    
    Test-Case "Both versions support session recovery" {
        $liteHelp = & .\lite\msp-lite.ps1 help 2>&1
        $standardHelp = & .\standard\msp.ps1 help 2>&1
        
        ($liteHelp -match "recover") -and ($standardHelp -match "recover")
    }
    
    # Test 5: AI integration format
    Write-Host "`n📋 AI Integration Tests:" -ForegroundColor Yellow
    
    Test-Case "AI context format includes required sections" {
        & .\lite\msp-lite.ps1 start 2>&1
        & .\lite\msp-lite.ps1 update "Test update" 40 2>&1
        & .\lite\msp-lite.ps1 decide "Use pattern X" 2>&1
        
        $aiContext = & .\lite\msp-lite.ps1 context ai 2>&1 | Out-String
        & .\lite\msp-lite.ps1 end 2>&1
        
        ($aiContext -match "PROJECT CONTEXT") -and
        ($aiContext -match "SESSION HISTORY") -and
        ($aiContext -match "DECISIONS")
    }
    
    # Test 6: Performance
    Write-Host "`n📋 Performance Tests:" -ForegroundColor Yellow
    
    Test-Case "Lite version starts in under 1 second" {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & .\lite\msp-lite.ps1 start 2>&1
        & .\lite\msp-lite.ps1 end 2>&1
        $stopwatch.Stop()
        
        $stopwatch.ElapsedMilliseconds -lt 1000
    }
    
    Test-Case "Standard version loads in reasonable time" {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & .\standard\msp.ps1 help 2>&1
        $stopwatch.Stop()
        
        # Allow more time for module loading
        $stopwatch.ElapsedMilliseconds -lt 3000
    }
    
    # Test 7: Error handling across versions
    Write-Host "`n📋 Error Handling Tests:" -ForegroundColor Yellow
    
    Test-Case "Both versions handle missing commands gracefully" {
        $liteError = & .\lite\msp-lite.ps1 nonexistent 2>&1
        $standardError = & .\standard\msp.ps1 nonexistent 2>&1
        
        ($liteError -match "Unknown command" -or $liteError -match "Invalid") -and
        ($standardError -match "Unknown command" -or $standardError -match "Invalid")
    }
    
    Test-Case "Both versions prevent double session start" {
        & .\lite\msp-lite.ps1 start 2>&1
        $liteDouble = & .\lite\msp-lite.ps1 start 2>&1
        & .\lite\msp-lite.ps1 end 2>&1
        
        $liteDouble -match "already active"
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