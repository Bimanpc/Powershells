﻿@{

# Script module or binary module file associated with this manifest.
RootModule = 'Azure.Storage.psm1'

# Version number of this module.
ModuleVersion = '2022'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '00612bca-fa22-401d-a671-9cc48b010e3b'

# Author of this module
Author = 'BILLMAN'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
DotNetFrameworkVersion = '4.5.2'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
CLRVersion = '4.0'

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = '.\Microsoft.WindowsAzure.Storage.dll',
               '.\Microsoft.WindowsAzure.Storage.DataMovement.dll',
               '.\Microsoft.Azure.KeyVault.Core.dll',
               '.\Microsoft.WindowsAzure.Management.dll', '.\Microsoft.Data.Edm.dll',
               '.\Microsoft.Data.OData.dll', '.\System.Net.Http.Formatting.dll',
               '.\System.Spatial.dll'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = '.\Microsoft.WindowsAzure.Commands.Storage.Types.ps1xml'

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = '.\Microsoft.WindowsAzure.Commands.Storage.format.ps1xml',
               '.\Microsoft.WindowsAzure.Commands.Storage.generated.format.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @()

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = 'Get-AzureStorageTable', 'New-AzureStorageTableSASToken',
               'New-AzureStorageTableStoredAccessPolicy', 'New-AzureStorageTable',
               'Remove-AzureStorageTableStoredAccessPolicy',
               'Remove-AzureStorageTable',
               'Get-AzureStorageTableStoredAccessPolicy',
               'Set-AzureStorageTableStoredAccessPolicy', 'Get-AzureStorageQueue',
               'New-AzureStorageQueue', 'Remove-AzureStorageQueue',
               'Get-AzureStorageQueueStoredAccessPolicy',
               'New-AzureStorageQueueSASToken',
               'New-AzureStorageQueueStoredAccessPolicy',
               'Remove-AzureStorageQueueStoredAccessPolicy',
               'Set-AzureStorageQueueStoredAccessPolicy', 'Get-AzureStorageFile',
               'Get-AzureStorageFileContent', 'Get-AzureStorageFileCopyState',
               'Get-AzureStorageShare', 'Get-AzureStorageShareStoredAccessPolicy',
               'New-AzureStorageDirectory', 'New-AzureStorageFileSASToken',
               'New-AzureStorageShare', 'New-AzureStorageShareSASToken',
               'New-AzureStorageShareStoredAccessPolicy',
               'Remove-AzureStorageDirectory', 'Remove-AzureStorageFile',
               'Remove-AzureStorageShare',
               'Remove-AzureStorageShareStoredAccessPolicy',
               'Set-AzureStorageFileContent', 'Set-AzureStorageShareQuota',
               'Set-AzureStorageShareStoredAccessPolicy',
               'Start-AzureStorageFileCopy', 'Stop-AzureStorageFileCopy',
               'New-AzureStorageAccountSASToken', 'Set-AzureStorageCORSRule',
               'Get-AzureStorageCORSRule',
               'Get-AzureStorageServiceLoggingProperty',
               'Get-AzureStorageServiceMetricsProperty',
               'Remove-AzureStorageCORSRule',
               'Set-AzureStorageServiceLoggingProperty',
               'Set-AzureStorageServiceMetricsProperty', 'New-AzureStorageContext',
               'Set-AzureStorageContainerAcl', 'Remove-AzureStorageBlob',
               'Set-AzureStorageBlobContent', 'Get-AzureStorageBlob',
               'Get-AzureStorageBlobContent', 'Get-AzureStorageBlobCopyState',
               'Get-AzureStorageContainer',
               'Get-AzureStorageContainerStoredAccessPolicy',
               'New-AzureStorageBlobSASToken', 'New-AzureStorageContainer',
               'New-AzureStorageContainerSASToken',
               'New-AzureStorageContainerStoredAccessPolicy',
               'Remove-AzureStorageContainer',
               'Remove-AzureStorageContainerStoredAccessPolicy',
               'Set-AzureStorageContainerStoredAccessPolicy',
               'Start-AzureStorageBlobCopy',
               'Start-AzureStorageBlobIncrementalCopy',
               'Stop-AzureStorageBlobCopy', 'Update-AzureStorageServiceProperty',
               'Get-AzureStorageServiceProperty',
               'Enable-AzureStorageDeleteRetentionPolicy',
               'Disable-AzureStorageDeleteRetentionPolicy'

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Get-AzureStorageContainerAcl', 'Start-CopyAzureStorageBlob',
               'Stop-CopyAzureStorageBlob', 'Enable-AzureStorageSoftDelete',
               'Disable-AzureStorageSoftDelete'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Azure','Storage','Blob','Queue','Table'

        # A URL to the license for this module.
        LicenseUri = 'https://aka.ms/azps-license'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Azure/azure-powershell'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '* Fix Copy Blob/File won''t copy metadata when destination has metadata issue
    - Start-AzureStorageBlobCopy
    - Start-AzureStorageFileCopy'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}