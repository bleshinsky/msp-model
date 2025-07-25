# Create MSP Obsidian folder structure
$folders = @(
    "Architecture",
    "Decisions", 
    "Development",
    "Meetings",
    "Research"
)

$basePath = "[OBSIDIAN-PROJECT-PATH]\Projects\MSP"

foreach ($folder in $folders) {
    $path = "$basePath\$folder"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
        Write-Host "Created: $folder" -ForegroundColor Green
    }
}

Write-Host "✅ Obsidian structure created" -ForegroundColor Cyan
