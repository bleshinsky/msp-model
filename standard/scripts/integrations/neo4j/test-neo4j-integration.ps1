# test-neo4j-integration.ps1
# Test script for MSP Neo4j Integration

[CmdletBinding()]
param(
    [string]$Neo4jUri = "bolt://localhost:7687",
    [string]$Neo4jUsername = "neo4j",
    [SecureString]$Neo4jPassword
)

$ErrorActionPreference = 'Stop'

Write-Host "MSP Neo4j Integration Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Get password if not provided
if (-not $Neo4jPassword) {
    $Neo4jPassword = Read-Host "Enter Neo4j password" -AsSecureString
}

# Convert SecureString to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Neo4jPassword)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Import module
Write-Host "`nImporting Neo4j module..." -ForegroundColor Yellow
Import-Module (Join-Path $PSScriptRoot "MSP.Neo4j.psd1") -Force

# Test results
$testResults = @()

function Test-Feature {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "`nTesting: $Name" -ForegroundColor Yellow
    try {
        & $Test
        Write-Host "✓ PASSED" -ForegroundColor Green
        $script:testResults += @{Feature = $Name; Result = "PASSED"; Error = $null}
    }
    catch {
        Write-Host "✗ FAILED: $_" -ForegroundColor Red
        $script:testResults += @{Feature = $Name; Result = "FAILED"; Error = $_.ToString()}
    }
}

# Run tests
Test-Feature "Connection" {
    $connected = Connect-Neo4j -Uri $Neo4jUri -Username $Neo4jUsername -Password $PlainPassword
    if (-not $connected) { throw "Connection failed" }
}

Test-Feature "Connection Test" {
    $isConnected = Test-Neo4jConnection
    if (-not $isConnected) { throw "Connection test failed" }
}

Test-Feature "Create Session" {
    $sessionId = [Guid]::NewGuid().ToString()
    $session = New-SessionNode -SessionId $sessionId -User "test-user" -Properties @{
        project = "MSP"
        environment = "test"
    }
    if (-not $session) { throw "Failed to create session" }
    $script:testSessionId = $sessionId
}

Test-Feature "Update Progress" {
    if (-not $script:testSessionId) { throw "No test session available" }
    $result = Update-SessionProgress -SessionId $script:testSessionId -Progress 25 -Message "Test progress update"
    if (-not $result) { throw "Failed to update progress" }
}

Test-Feature "Add Entity" {
    if (-not $script:testSessionId) { throw "No test session available" }
    $entity = Add-EntityNode -SessionId $script:testSessionId `
        -EntityName "TestService" `
        -EntityType "Service" `
        -Properties @{testProp = "value"} `
        -Observations @("Test observation 1", "Test observation 2")
    if (-not $entity) { throw "Failed to add entity" }
}

Test-Feature "Add Decision" {
    if (-not $script:testSessionId) { throw "No test session available" }
    $decision = Add-DecisionNode -SessionId $script:testSessionId `
        -Decision "Use test framework" `
        -Rationale "For testing purposes" `
        -Alternatives @("Alternative 1", "Alternative 2")
    if (-not $decision) { throw "Failed to add decision" }
}

Test-Feature "Get Active Session" {
    $activeSession = Get-ActiveSession -User "test-user"
    if (-not $activeSession) { throw "Failed to get active session" }
    if ($activeSession.Values["s"].Properties.id -ne $script:testSessionId) {
        throw "Active session ID mismatch"
    }
}

Test-Feature "Session Integrity" {
    if (-not $script:testSessionId) { throw "No test session available" }
    $integrity = Test-SessionIntegrity -SessionId $script:testSessionId
    $isValid = $integrity[0].Values["isValid"]
    if (-not $isValid) { throw "Session integrity check failed" }
}

Test-Feature "Session History" {
    $history = Get-SessionHistory -User "test-user" -Limit 5
    if ($history.Count -eq 0) { throw "No session history found" }
}

Test-Feature "Close Session" {
    if (-not $script:testSessionId) { throw "No test session available" }
    $closed = Close-SessionNode -SessionId $script:testSessionId -Summary "Test completed"
    if (-not $closed) { throw "Failed to close session" }
}

Test-Feature "Custom Query" {
    $result = Invoke-Neo4jQuery -Query "MATCH (n) RETURN count(n) AS nodeCount" -ReadOnly
    $count = $result[0].Values["nodeCount"]
    Write-Host "  Total nodes in database: $count" -ForegroundColor Gray
}

# Cleanup test data
Test-Feature "Cleanup" {
    $cleanup = Invoke-Neo4jQuery -Query @"
        MATCH (s:Session {user: 'test-user'})
        OPTIONAL MATCH (s)-[r1]->(n1)
        OPTIONAL MATCH (n1)-[r2]->(n2)
        DELETE r2, n2, r1, n1, s
"@
    Write-Host "  Test data cleaned up" -ForegroundColor Gray
}

# Disconnect
Disconnect-Neo4j

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$passed = ($testResults | Where-Object { $_.Result -eq "PASSED" }).Count
$failed = ($testResults | Where-Object { $_.Result -eq "FAILED" }).Count

Write-Host "Total Tests: $($testResults.Count)" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $testResults | Where-Object { $_.Result -eq "FAILED" } | ForEach-Object {
        Write-Host "- $($_.Feature): $($_.Error)" -ForegroundColor Red
    }
}

# Cleanup
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
Clear-Variable PlainPassword

# Exit code
exit $(if ($failed -gt 0) { 1 } else { 0 })
