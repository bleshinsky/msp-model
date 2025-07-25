# MSP.Neo4j.psd1
# Module manifest for MSP Neo4j Integration

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'neo4j-connection.ps1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a8f4e3d2-9c7b-4e5a-b1d3-8f2a6c9e7d3b'
    
    # Author of this module
    Author = 'MSP Team'
    
    # Company or vendor of this module
    CompanyName = 'Session Protocol'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Session Protocol. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Neo4j integration module for Mandatory Session Protocol (MSP). Provides connection management and graph operations for session tracking.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @(
        'Neo4j.Driver.dll'
    )
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Connect-Neo4j',
        'Disconnect-Neo4j',
        'Test-Neo4jConnection',
        'Invoke-Neo4jQuery',
        'New-SessionNode',
        'Update-SessionProgress',
        'Add-EntityNode',
        'Add-DecisionNode',
        'Get-ActiveSession',
        'Close-SessionNode',
        'Get-SessionHistory',
        'Test-SessionIntegrity'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Neo4j', 'GraphDatabase', 'SessionTracking', 'MSP')
            
            # A URL to the license for this module
            LicenseUri = 'https://sessionprotocol.dev/license'
            
            # A URL to the main website for this project
            ProjectUri = 'https://sessionprotocol.dev'
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of MSP Neo4j integration module'
        }
    }
}
