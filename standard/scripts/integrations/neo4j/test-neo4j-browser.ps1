# test-neo4j-browser.ps1
# Quick test to verify Neo4j Browser is accessible

Write-Host "Testing Neo4j Browser Connection" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test if Neo4j is running
$neo4jUrl = "http://localhost:7474"
try {
    $response = Invoke-WebRequest -Uri $neo4jUrl -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Neo4j Browser is accessible at $neo4jUrl" -ForegroundColor Green
        
        # Open browser
        Write-Host "`nOpening Neo4j Browser..." -ForegroundColor Yellow
        Start-Process $neo4jUrl
        
        # Provide test query
        $testQuery = @"
// Test Query - Verify Neo4j is working
CREATE (test:TestNode {
    name: 'MSP Test',
    timestamp: datetime(),
    message: 'Neo4j integration test successful'
})
RETURN test
"@
        
        try {
            $testQuery | Set-Clipboard
            Write-Host "✅ Test query copied to clipboard!" -ForegroundColor Green
        } catch {
            Write-Host "Copy this test query:" -ForegroundColor Yellow
        }
        
        Write-Host "`nTEST QUERY:" -ForegroundColor Cyan
        Write-Host $testQuery -ForegroundColor Yellow
        
        Write-Host "`nPaste and run this in Neo4j Browser to verify it's working." -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Cannot connect to Neo4j Browser at $neo4jUrl" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nMake sure Neo4j is running in Neo4j Desktop!" -ForegroundColor Yellow
}
