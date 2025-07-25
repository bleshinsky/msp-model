#Requires -Version 7.0
<#
.SYNOPSIS
    Runs all MSP test suites
.DESCRIPTION
    Executes tests for all MSP versions and generates a summary report
.EXAMPLE
    .\run-all.ps1
    .\run-all.ps1 -Version lite
    .\run-all.ps1 -Verbose
#>

[CmdletBinding()]
param(
    [ValidateSet('all', 'lite', 'standard', 'integration')]
    [string]$Version = 'all',
    
    [switch]$StopOnFailure,
    [switch]$GenerateReport
)

$ErrorActionPreference = 'Stop'
$testResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
}

# Test runner function
function Run-TestSuite {
    param(
        [string]$Name,
        [string]$Path,
        [hashtable]$Results
    )
    
    Write-Host "`n🧪 Running $Name Tests..." -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor DarkGray
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Test file not found: $Path"
        $Results.Skipped++
        return
    }
    
    try {
        $testResult = & $Path
        
        if ($testResult.Failed -eq 0) {
            Write-Host "✅ $Name tests passed!" -ForegroundColor Green
            $Results.Passed += $testResult.Passed
        } else {
            Write-Host "❌ $Name tests failed: $($testResult.Failed) failures" -ForegroundColor Red
            $Results.Failed += $testResult.Failed
            
            if ($StopOnFailure) {
                throw "Test suite failed: $Name"
            }
        }
        
        $Results.Total += $testResult.Total
        $Results.Details += @{
            Suite = $Name
            Result = $testResult
        }
        
    } catch {
        Write-Error "Error running $Name tests: $_"
        $Results.Failed++
        
        if ($StopOnFailure) {
            throw
        }
    }
}

# Main test execution
Write-Host "MSP Test Runner v1.0" -ForegroundColor Magenta
Write-Host "Running tests for: $Version" -ForegroundColor Yellow

$startTime = Get-Date

try {
    # Run tests based on version
    switch ($Version) {
        'all' {
            Run-TestSuite -Name "MSP Lite" -Path "$PSScriptRoot\lite\test-msp-lite.ps1" -Results $testResults
            Run-TestSuite -Name "MSP Standard" -Path "$PSScriptRoot\standard\test-msp-standard.ps1" -Results $testResults
            Run-TestSuite -Name "Integration" -Path "$PSScriptRoot\integration\test-integration.ps1" -Results $testResults
        }
        'lite' {
            Run-TestSuite -Name "MSP Lite" -Path "$PSScriptRoot\lite\test-msp-lite.ps1" -Results $testResults
        }
        'standard' {
            Run-TestSuite -Name "MSP Standard" -Path "$PSScriptRoot\standard\test-msp-standard.ps1" -Results $testResults
        }
        'integration' {
            Run-TestSuite -Name "Integration" -Path "$PSScriptRoot\integration\test-integration.ps1" -Results $testResults
        }
    }
    
    $duration = (Get-Date) - $startTime
    
    # Display summary
    Write-Host "`n📊 Test Summary" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor DarkGray
    Write-Host "Total Tests:    $($testResults.Total)" -ForegroundColor White
    Write-Host "Passed:         $($testResults.Passed)" -ForegroundColor Green
    Write-Host "Failed:         $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "Skipped:        $($testResults.Skipped)" -ForegroundColor Yellow
    Write-Host "Duration:       $($duration.TotalSeconds.ToString('F2'))s" -ForegroundColor White
    
    # Generate report if requested
    if ($GenerateReport) {
        $reportPath = "$PSScriptRoot\test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $report = @{
            Date = Get-Date -Format 'o'
            Duration = $duration.TotalSeconds
            Version = $Version
            Results = $testResults
            Environment = @{
                OS = $PSVersionTable.OS
                PowerShell = $PSVersionTable.PSVersion.ToString()
                User = $env:USERNAME
            }
        }
        
        $report | ConvertTo-Json -Depth 10 | Out-File $reportPath
        Write-Host "`n📄 Report saved to: $reportPath" -ForegroundColor Blue
    }
    
    # Exit code based on results
    if ($testResults.Failed -gt 0) {
        exit 1
    }
    
} catch {
    Write-Error "Test execution failed: $_"
    exit 1
}

Write-Host "`n✨ All tests completed!" -ForegroundColor Green