@{

# Script module or binary module file associated with this manifest.
RootModule = 'Get-WindowsVersion.psm1'

# Version number of this module.
ModuleVersion = '2022'

# Supported PSEditions
CompatiblePSEditions = 'Desktop', 'Core'

# Author of this module
Author = 'PCTECHGR'

# Company or vendor of this module
CompanyName = 'Xrimatistririo eneergeias xefltismeno'

# Copyright statement for this module
Copyright = '(c) 2022.'

# Description of the functionality provided by this module
Description = 'List current or History Windows Version from local computer.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'Get-WindowsVersion.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Get-WindowsVersion'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'gwv'

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
        Tags = 'Build','History','ProductID','Version','Windows'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://www.dertechblog.de/'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
 
## 1.3.9
 
* Code Optimization and Bug Fixes for Windows 11
 
## 1.3.8
 
* Code Optimization and Bug Fixes
 
## 1.3.7
 
* Code Optimization and Bug Fixes
* Display of the correct Version from 20H2 or higher
* Add new Example with Sort-Object
 
## 1.3.6
 
* Code Optimization and Bug Fixes
* Minimum PSVersion: 5.1
* Remove Parameter ADSearchBase
* Remove Parameter ComputerName
* Supported PSEditions: Desktop and Core
 
## 1.3.5
 
* Code Optimization and Bug Fixes for PowerShell 7
* Faster with ForEach-Object -Parallel
* Minimum PSVersion: 7.0
* New-Alias gwv
* Remove Parameter Force (Replace Output Format with Format.ps1xml)
* Remove Parameter TestWinRM
* Supported PSEditions: Core
 
## 1.3.4
 
* Code Optimization
* Default Test-NetConnection is now Ping (instead of before WinRM)
* New Parameter TestWinRM for Test-NetConnection with TCPPort WinRM
 
## 1.3.3
 
* Change AD Search to System.DirectoryServices.DirectorySearcher
 
## 1.3.2
 
* Code Optimization and Bug Fixes
* Supported PSEditions: Desktop and Core
* Minimum PSVersion: 5.1
 
## 1.3.1
 
* Minimum requirement PowerShell Version 5.1
* New: Compatible with PowerShell Core 6
* Code Optimization and Bug Fixes
 
## 1.3.0
 
* Change PowerShell Version to 3.0
 
## 1.2.8
 
* Change Module Manifest Release Notes
 
## 1.2.7
 
* Change Module Manifest Description and Tags
 
## 1.2.6
 
* New Module Manifest
 
## 1.2.5
 
* Code Optimization
 
## 1.2.4
 
* BugFix Error Handling WMI Access
* BugFix InstallTime for Windows 6.x
 
## 1.2.3
 
* Colum InstallTime Optimization
 
## 1.2.2
 
* BugFix Error Handling
* New parameter History
* New column InstallTime
 
## 1.2.1
 
* BugFix Error Handling
 
## 1.2.0
 
* Compatible with local Computers without domain membership
 
## 1.1.0
 
* Added Force Parameter to disable the built-in Format-Table and Sort-Object
 
## 1.0.0
 
* Initial Upload'

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
