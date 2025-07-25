<#
.SYNOPSIS
    Error handling and logging for MSP Standard
.DESCRIPTION
    Provides consistent error handling, logging, and recovery mechanisms
#>

$script:LogFile = Join-Path ".msp" "msp.log"

function Write-MSPLog {
    <#
    .SYNOPSIS
        Writes a log message to console and file
    .PARAMETER Message
        The message to log
    .PARAMETER Level
        Log level: Info, Warning, Error, Debug
    .PARAMETER NoFile
        Skip writing to log file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',
        
        [switch]$NoFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        'Error' { 
            Write-Host "❌ $Message" -ForegroundColor Red 
        }
        'Warning' { 
            Write-Host "⚠️  $Message" -ForegroundColor Yellow 
        }
        'Debug' { 
            if ($env:MSP_DEBUG -eq 'true') {
                Write-Host "🔍 $Message" -ForegroundColor Gray 
            }
        }
        default { 
            Write-Host "$Message" -ForegroundColor White 
        }
    }
    
    # File logging
    if (-not $NoFile) {
        try {
            if (-not (Test-Path (Split-Path $script:LogFile -Parent))) {
                New-Item -Path (Split-Path $script:LogFile -Parent) -ItemType Directory -Force | Out-Null
            }
            Add-Content -Path $script:LogFile -Value $logMessage -ErrorAction SilentlyContinue
        } catch {
            # Silently fail file logging
        }
    }
}

function Invoke-MSPAction {
    <#
    .SYNOPSIS
        Executes an action with error handling
    .PARAMETER Action
        Script block to execute
    .PARAMETER ErrorMessage
        Custom error message
    .PARAMETER ContinueOnError
        Continue execution even if error occurs
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        
        [string]$ErrorMessage = "An error occurred",
        
        [switch]$ContinueOnError
    )
    
    try {
        & $Action
    } catch {
        Write-MSPLog "$ErrorMessage`: $_" -Level Error
        
        if (-not $ContinueOnError) {
            throw
        }
    }
}

function Test-MSPPrerequisites {
    <#
    .SYNOPSIS
        Checks if all prerequisites are met
    .DESCRIPTION
        Validates PowerShell version, required modules, and permissions
    #>
    
    $issues = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $issues += "PowerShell 7+ required (current: $($PSVersionTable.PSVersion))"
    }
    
    # Check write permissions
    try {
        $testFile = Join-Path "." "msp-test-$(Get-Random).tmp"
        "test" | Out-File $testFile -ErrorAction Stop
        Remove-Item $testFile -Force
    } catch {
        $issues += "No write permission in current directory"
    }
    
    # Check for .msp directory
    if (-not (Test-Path ".msp")) {
        try {
            New-Item -Path ".msp" -ItemType Directory -Force | Out-Null
        } catch {
            $issues += "Cannot create .msp directory"
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-MSPLog "Prerequisites check failed:" -Level Error
        $issues | ForEach-Object { Write-MSPLog "  - $_" -Level Error }
        return $false
    }
    
    return $true
}

function Get-MSPErrorContext {
    <#
    .SYNOPSIS
        Gets context information for error reporting
    #>
    
    return @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        User = $env:USERNAME
        ComputerName = $env:COMPUTERNAME
        PSVersion = $PSVersionTable.PSVersion.ToString()
        OSVersion = [System.Environment]::OSVersion.ToString()
        CurrentDirectory = Get-Location
        SessionState = if (Test-Path ".msp\current-session.json") { 
            Get-Content ".msp\current-session.json" | ConvertFrom-Json 
        } else { 
            $null 
        }
    }
}

function Save-MSPErrorReport {
    <#
    .SYNOPSIS
        Saves detailed error report for troubleshooting
    #>
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [string]$AdditionalInfo
    )
    
    $errorDir = Join-Path ".msp" "errors"
    if (-not (Test-Path $errorDir)) {
        New-Item -Path $errorDir -ItemType Directory -Force | Out-Null
    }
    
    $errorFile = Join-Path $errorDir "error-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    
    $errorReport = @{
        Error = @{
            Message = $ErrorRecord.Exception.Message
            Type = $ErrorRecord.Exception.GetType().FullName
            StackTrace = $ErrorRecord.ScriptStackTrace
            InvocationInfo = @{
                ScriptName = $ErrorRecord.InvocationInfo.ScriptName
                Line = $ErrorRecord.InvocationInfo.Line
                PositionMessage = $ErrorRecord.InvocationInfo.PositionMessage
            }
        }
        Context = Get-MSPErrorContext
        AdditionalInfo = $AdditionalInfo
    }
    
    $errorReport | ConvertTo-Json -Depth 10 | Out-File $errorFile -Encoding UTF8
    
    Write-MSPLog "Error report saved to: $errorFile" -Level Warning
    
    return $errorFile
}

function Show-MSPError {
    <#
    .SYNOPSIS
        Shows user-friendly error message with recovery options
    #>
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [string]$UserMessage = "An error occurred during MSP operation"
    )
    
    Write-Host "`n❌ $UserMessage" -ForegroundColor Red
    Write-Host "Error: $($ErrorRecord.Exception.Message)" -ForegroundColor Red
    
    # Save error report
    $reportFile = Save-MSPErrorReport -ErrorRecord $ErrorRecord
    
    Write-Host "`n💡 Recovery Options:" -ForegroundColor Yellow
    Write-Host "  1. Run '.\msp.ps1 validate' to check system state" -ForegroundColor White
    Write-Host "  2. Run '.\msp.ps1 recover' to recover from crash" -ForegroundColor White
    Write-Host "  3. Check error report: $reportFile" -ForegroundColor White
    Write-Host "  4. View logs: .msp\msp.log" -ForegroundColor White
    Write-Host ""
}

# Export functions
Export-ModuleMember -Function Write-MSPLog, Invoke-MSPAction, Test-MSPPrerequisites, Get-MSPErrorContext, Save-MSPErrorReport, Show-MSPError
