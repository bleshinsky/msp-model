#Requires -Version 7.0
<#
.SYNOPSIS
    Test suite for MSP Standard (NOL Framework)
.DESCRIPTION
    Tests core functionality and integrations for MSP Standard
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
$testDir = Join-Path $env:TEMP "msp-standard-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
Push-Location $testDir

try {
    # Copy MSP Standard files
    $mspStandardPath = Join-Path $PSScriptRoot "..\..\standard"
    Copy-Item "$mspStandardPath\*" -Destination . -Recurse -Force
    
    Write-Host "`n🧪 MSP Standard Test Suite" -ForegroundColor Cyan
    Write-Host "Test Directory: $testDir" -ForegroundColor Gray
    
    # Test 1: File structure
    Write-Host "`n📋 Structure Tests:" -ForegroundColor Yellow
    
    Test-Case "Main script exists" {
        Test-Path ".\msp.ps1"
    }
    
    Test-Case "Scripts directory exists" {
        Test-Path ".\scripts"
    }
    
    Test-Case "Core scripts present" {
        (Test-Path ".\scripts\core\msp-core.ps1") -and
        (Test-Path ".\scripts\core\msp-automation.ps1") -and
        (Test-Path ".\scripts\core\msp-validate.ps1")
    }
    
    Test-Case "Integration scripts present" {
        (Test-Path ".\scripts\integrations\neo4j") -and
        (Test-Path ".\scripts\integrations\obsidian") -and
        (Test-Path ".\scripts\integrations\linear")
    }
    
    # Test 2: Configuration
    Write-Host "`n📋 Configuration Tests:" -ForegroundColor Yellow
    
    Test-Case "Example config exists" {
        Test-Path ".\config\msp-config.example.json"
    }
    
    Test-Case "Can create config from example" {
        Copy-Item ".\config\msp-config.example.json" ".\config\msp-config.json"
        Test-Path ".\config\msp-config.json"
    }
    
    Test-Case "Config is valid JSON" {
        $config = Get-Content ".\config\msp-config.json" -Raw | ConvertFrom-Json
        $config.version -and $config.integrations
    }
    
    # Test 3: Basic commands
    Write-Host "`n📋 Command Tests:" -ForegroundColor Yellow
    
    Test-Case "Help command works" {
        $output = & .\msp.ps1 help 2>&1
        $output -match "MSP.*Standard"
    }
    
    Test-Case "Version command" {
        $output = & .\msp.ps1 version 2>&1
        $output -match "Standard"
    }
    
    Test-Case "Config command" {
        $output = & .\msp.ps1 config show 2>&1
        $output -match "integrations"
    }
    
    # Test 4: Module loading
    Write-Host "`n📋 Module Tests:" -ForegroundColor Yellow
    
    Test-Case "Can load core module" {
        . .\scripts\core\msp-core.ps1
        Get-Command Initialize-MSPSession -ErrorAction SilentlyContinue
    }
    
    Test-Case "Can load config module" {
        . .\scripts\core\msp-config.ps1
        Get-Command Get-MSPConfig -ErrorAction SilentlyContinue
    }
    
    # Test 5: Integration detection
    Write-Host "`n📋 Integration Tests:" -ForegroundColor Yellow
    
    Test-Case "Neo4j integration check" {
        $output = & .\msp.ps1 check neo4j 2>&1
        $output -match "Neo4j"
    }
    
    Test-Case "Obsidian integration check" {
        $output = & .\msp.ps1 check obsidian 2>&1
        $output -match "Obsidian"
    }
    
    Test-Case "Linear integration check" {
        $output = & .\msp.ps1 check linear 2>&1
        $output -match "Linear"
    }
    
    # Test 6: Session simulation (without actual integrations)
    Write-Host "`n📋 Session Simulation Tests:" -ForegroundColor Yellow
    
    # Create a test mode config
    $testConfig = @{
        version = "standard"
        mode = "test"
        integrations = @{
            neo4j = @{ enabled = $false }
            obsidian = @{ enabled = $false }
            linear = @{ enabled = $false }
        }
        paths = @{
            state = ".\.msp"
        }
    }
    $testConfig | ConvertTo-Json -Depth 10 | Out-File ".\config\msp-config.json"
    
    Test-Case "Start session in test mode" {
        $output = & .\msp.ps1 start 2>&1
        $output -match "Session started" -or $output -match "test mode"
    }
    
    Test-Case "Status in test mode" {
        $output = & .\msp.ps1 status 2>&1
        $output -match "session" -or $output -match "No active"
    }
    
    # Test 7: Validation
    Write-Host "`n📋 Validation Tests:" -ForegroundColor Yellow
    
    Test-Case "Validation script exists" {
        Test-Path ".\scripts\core\msp-validate.ps1"
    }
    
    Test-Case "Can run validation" {
        $output = & .\msp.ps1 validate 2>&1
        # Should not throw error
        $true
    }
    
    # Test 8: Recovery
    Write-Host "`n📋 Recovery Tests:" -ForegroundColor Yellow
    
    Test-Case "Recovery script exists" {
        Test-Path ".\scripts\core\msp-recovery.ps1"
    }
    
    Test-Case "Can list sessions" {
        $output = & .\msp.ps1 sessions 2>&1
        # Should not throw error
        $true
    }
    
    # Clean up any test sessions
    if (Test-Path ".\.msp\current-session.json") {
        Remove-Item ".\.msp\current-session.json" -Force
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