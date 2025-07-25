# download-neo4j-driver.ps1
# Download Neo4j driver without .NET SDK

[CmdletBinding()]
param(
    [string]$Version = "5.15.0"
)

$ErrorActionPreference = 'Stop'

Write-Host "Downloading Neo4j.Driver v$Version..." -ForegroundColor Yellow

$packageUrl = "https://www.nuget.org/api/v2/package/Neo4j.Driver/$Version"
$tempPath = Join-Path $env:TEMP "neo4j-driver-download"
$zipPath = Join-Path $tempPath "neo4j.driver.zip"
$dllPath = Join-Path $PSScriptRoot "Neo4j.Driver.dll"

try {
    # Create temp directory
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    
    # Download package
    Write-Host "Downloading from NuGet..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $packageUrl -OutFile $zipPath -UseBasicParsing
    
    # Extract package
    Write-Host "Extracting package..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $tempPath -Force
    
    # Find and copy the DLL
    $dll = Get-ChildItem -Path $tempPath -Recurse -Filter "Neo4j.Driver.dll" | 
           Where-Object { $_.DirectoryName -like "*net6.0*" -or $_.DirectoryName -like "*netstandard2.0*" } |
           Select-Object -First 1
    
    if ($dll) {
        Copy-Item $dll.FullName $dllPath -Force
        Write-Host "Successfully downloaded Neo4j.Driver.dll to:" -ForegroundColor Green
        Write-Host $dllPath -ForegroundColor Green
        
        # Also copy dependencies if they exist
        $dependencies = @("System.Threading.Tasks.Extensions.dll", "System.ValueTuple.dll")
        foreach ($dep in $dependencies) {
            $depFile = Get-ChildItem -Path $tempPath -Recurse -Filter $dep | Select-Object -First 1
            if ($depFile) {
                Copy-Item $depFile.FullName $PSScriptRoot -Force
                Write-Host "Also copied dependency: $dep" -ForegroundColor Gray
            }
        }
    } else {
        throw "Could not find Neo4j.Driver.dll in the package"
    }
    
    # Cleanup
    Remove-Item $tempPath -Recurse -Force
    
    Write-Host "`nDriver downloaded successfully!" -ForegroundColor Green
    Write-Host "You can now run the setup script with -SkipDriverInstall flag" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to download Neo4j driver: $_"
    Write-Host "`nAlternative: Download manually from:" -ForegroundColor Yellow
    Write-Host "https://www.nuget.org/packages/Neo4j.Driver/$Version" -ForegroundColor Cyan
    Write-Host "Extract and copy Neo4j.Driver.dll to: $PSScriptRoot" -ForegroundColor Cyan
}
