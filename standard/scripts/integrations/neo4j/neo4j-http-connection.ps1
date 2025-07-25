# neo4j-http-connection.ps1
# Alternative Neo4j connection using HTTP API (no driver needed)

[CmdletBinding()]
param()

# Module configuration
$script:Neo4jConfig = @{
    Uri = $env:NEO4J_URI ?? "http://localhost:7474"
    Username = $env:NEO4J_USERNAME ?? "neo4j"
    Password = $env:NEO4J_PASSWORD ?? "password"
    Database = $env:NEO4J_DATABASE ?? "neo4j"
}

$script:AuthHeader = $null

function Connect-Neo4jHTTP {
    [CmdletBinding()]
    param(
        [string]$Uri = $script:Neo4jConfig.Uri,
        [string]$Username = $script:Neo4jConfig.Username,
        [string]$Password
    )
    
    try {
        # Create basic auth header
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
        $script:AuthHeader = @{
            Authorization = "Basic $auth"
            'Content-Type' = 'application/json'
            Accept = 'application/json'
        }
        
        # Test connection
        $testUri = "$Uri/db/$($script:Neo4jConfig.Database)/tx"
        $body = @{
            statements = @(
                @{
                    statement = "RETURN 'Connected' AS status"
                }
            )
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri $testUri -Method Post -Headers $script:AuthHeader -Body $body
        
        if ($response.results[0].data[0].row[0] -eq 'Connected') {
            Write-Host "Successfully connected to Neo4j via HTTP" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Error "Failed to connect to Neo4j: $_"
        return $false
    }
}

function Invoke-Neo4jQueryHTTP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        
        [hashtable]$Parameters = @{}
    )
    
    if (-not $script:AuthHeader) {
        throw "Not connected to Neo4j. Call Connect-Neo4jHTTP first."
    }
    
    try {
        $uri = "$($script:Neo4jConfig.Uri)/db/$($script:Neo4jConfig.Database)/tx/commit"
        
        $body = @{
            statements = @(
                @{
                    statement = $Query
                    parameters = $Parameters
                }
            )
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $script:AuthHeader -Body $body
        
        if ($response.errors.Count -gt 0) {
            throw "Neo4j error: $($response.errors[0].message)"
        }
        
        return $response.results[0].data
    }
    catch {
        throw "Query failed: $_"
    }
}

# Test function
function Test-Neo4jHTTPConnection {
    Write-Host "Testing Neo4j HTTP connection..." -ForegroundColor Yellow
    
    $password = Read-Host "Enter Neo4j password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    try {
        $connected = Connect-Neo4jHTTP -Password $plainPassword
        if ($connected) {
            # Run test query
            $result = Invoke-Neo4jQueryHTTP -Query "RETURN datetime() AS now, 'HTTP API Test' AS message"
            Write-Host "Test successful! Current time: $($result[0].row[0])" -ForegroundColor Green
            Write-Host "Message: $($result[0].row[1])" -ForegroundColor Green
        }
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        Clear-Variable plainPassword -ErrorAction SilentlyContinue
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Connect-Neo4jHTTP',
    'Invoke-Neo4jQueryHTTP',
    'Test-Neo4jHTTPConnection'
)
