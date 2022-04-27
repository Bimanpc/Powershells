﻿# Module manifest for module 'Microsoft.Graph.Mail'
#
# Generated by: Microsoft Corporation
#
# Generated on: 4/13/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = './Microsoft.Graph.Mail.psm1'

# Version number of this module.
ModuleVersion = '1.9.5'

# Supported PSEditions
CompatiblePSEditions = 'Core', 'Desktop'

# ID used to uniquely identify this module
GUID = 'fd608372-7429-4747-ae41-c7446433f189'

# Author of this module
Author = 'Bilieye'

# Description of the functionality provided by this module
Description = 'Microsoft Graph PowerShell Cmdlets'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
DotNetFrameworkVersion = '4.7.2'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName = 'Microsoft.Graph.Auth'; ModuleVersion = '1.9.5'; })

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = './bin/Microsoft.Graph.Mail.private.dll'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = './Microsoft.Graph.Mail.format.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Get-MgUserInferenceClassification', 
               'Get-MgUserInferenceClassificationOverride', 'Get-MgUserMailFolder', 
               'Get-MgUserMailFolderChildFolder', 'Get-MgUserMailFolderMessage', 
               'Get-MgUserMailFolderMessageAttachment', 
               'Get-MgUserMailFolderMessageContent', 
               'Get-MgUserMailFolderMessageExtension', 
               'Get-MgUserMailFolderMessageMention', 
               'Get-MgUserMailFolderMessageMultiValueExtendedProperty', 
               'Get-MgUserMailFolderMessageRule', 
               'Get-MgUserMailFolderMessageSingleValueExtendedProperty', 
               'Get-MgUserMailFolderMultiValueExtendedProperty', 
               'Get-MgUserMailFolderSingleValueExtendedProperty', 
               'Get-MgUserMailFolderUserConfiguration', 'Get-MgUserMessage', 
               'Get-MgUserMessageAttachment', 'Get-MgUserMessageContent', 
               'Get-MgUserMessageExtension', 'Get-MgUserMessageMention', 
               'Get-MgUserMessageMultiValueExtendedProperty', 
               'Get-MgUserMessageSingleValueExtendedProperty', 
               'New-MgUserInferenceClassificationOverride', 'New-MgUserMailFolder', 
               'New-MgUserMailFolderChildFolder', 'New-MgUserMailFolderMessage', 
               'New-MgUserMailFolderMessageAttachment', 
               'New-MgUserMailFolderMessageExtension', 
               'New-MgUserMailFolderMessageMention', 
               'New-MgUserMailFolderMessageMultiValueExtendedProperty', 
               'New-MgUserMailFolderMessageRule', 
               'New-MgUserMailFolderMessageSingleValueExtendedProperty', 
               'New-MgUserMailFolderMultiValueExtendedProperty', 
               'New-MgUserMailFolderSingleValueExtendedProperty', 
               'New-MgUserMailFolderUserConfiguration', 'New-MgUserMessage', 
               'New-MgUserMessageAttachment', 'New-MgUserMessageExtension', 
               'New-MgUserMessageMention', 
               'New-MgUserMessageMultiValueExtendedProperty', 
               'New-MgUserMessageSingleValueExtendedProperty', 
               'Remove-MgUserInferenceClassification', 
               'Remove-MgUserInferenceClassificationOverride', 
               'Remove-MgUserMailFolder', 'Remove-MgUserMailFolderChildFolder', 
               'Remove-MgUserMailFolderMessage', 
               'Remove-MgUserMailFolderMessageAttachment', 
               'Remove-MgUserMailFolderMessageExtension', 
               'Remove-MgUserMailFolderMessageMention', 
               'Remove-MgUserMailFolderMessageMultiValueExtendedProperty', 
               'Remove-MgUserMailFolderMessageRule', 
               'Remove-MgUserMailFolderMessageSingleValueExtendedProperty', 
               'Remove-MgUserMailFolderMultiValueExtendedProperty', 
               'Remove-MgUserMailFolderSingleValueExtendedProperty', 
               'Remove-MgUserMailFolderUserConfiguration', 'Remove-MgUserMessage', 
               'Remove-MgUserMessageAttachment', 'Remove-MgUserMessageExtension', 
               'Remove-MgUserMessageMention', 
               'Remove-MgUserMessageMultiValueExtendedProperty', 
               'Remove-MgUserMessageSingleValueExtendedProperty', 
               'Set-MgUserMailFolderMessageContent', 'Set-MgUserMessageContent', 
               'Update-MgUserInferenceClassification', 
               'Update-MgUserInferenceClassificationOverride', 
               'Update-MgUserMailFolder', 'Update-MgUserMailFolderChildFolder', 
               'Update-MgUserMailFolderMessage', 
               'Update-MgUserMailFolderMessageAttachment', 
               'Update-MgUserMailFolderMessageExtension', 
               'Update-MgUserMailFolderMessageMention', 
               'Update-MgUserMailFolderMessageMultiValueExtendedProperty', 
               'Update-MgUserMailFolderMessageRule', 
               'Update-MgUserMailFolderMessageSingleValueExtendedProperty', 
               'Update-MgUserMailFolderMultiValueExtendedProperty', 
               'Update-MgUserMailFolderSingleValueExtendedProperty', 
               'Update-MgUserMailFolderUserConfiguration', 'Update-MgUserMessage', 
               'Update-MgUserMessageAttachment', 'Update-MgUserMessageExtension', 
               'Update-MgUserMessageMention', 
               'Update-MgUserMessageMultiValueExtendedProperty', 
               'Update-MgUserMessageSingleValueExtendedProperty'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    #Profiles of this module
    Profiles =  @('v1.0','v1.0-beta')

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Microsoft','Office365','Graph','PowerShell'

        # A URL to the license for this module.
        LicenseUri = 'https://aka.ms/devservicesagreement'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/microsoftgraph/msgraph-sdk-powershell'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/master/documentation/images/graph_color256.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'See https://aka.ms/GraphPowerShell-Release.'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
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
