# MSP Simple Error Handler
function Write-MSPLog {
    param($Message, $Level = 'Info')
    
    switch ($Level) {
        'Error' { Write-Host $Message -ForegroundColor Red }
        'Warning' { Write-Host $Message -ForegroundColor Yellow }
        'Info' { Write-Host $Message -ForegroundColor Gray }
    }
}
