@{
    # Version number of this module.
    moduleVersion        = '2022'

    # Author of this module
    Author               = 'PCTEHGREEU ARMADA PC  Community'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @('Computer','OfflineDomainJoin','PendingReboot','PowerPlan','PowerShellExecutionPolicy','RemoteDesktopAdmin','ScheduledTask','SmbServerConfiguration','SmbShare','SystemLocale','TimeZone','VirtualMemory','WindowsEventLog','WindowsCapability','IEEnhancedSecurityConfiguration','UserAccountControl')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''
            # ReleaseNotes of this module
            ReleaseNotes = '## [8.5.0] - 2021-09-13
 
### Added
 
-
'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}