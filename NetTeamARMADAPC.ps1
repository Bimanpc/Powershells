@{
    # Version number of this module.
    moduleVersion        = '2022'

   # Author of this module
    Author               = 'Truth Team LOVERS PCTECHGREU ARMADA PC '

   # Copyright statement for this module
    Copyright            = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'DSC resources for configuring settings related to networking.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion           = '4.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'DefaultGatewayAddress',
        'DnsClientGlobalSetting',
        'DnsConnectionSuffix',
        'DNSServerAddress',
        'Firewall',
        'FirewallProfile',
        'HostsFile',
        'IPAddress',
        'IPAddressOption',
        'NetAdapterAdvancedProperty',
        'NetAdapterBinding',
        'NetAdapterLso',
        'NetAdapterName',
        'NetAdapterRDMA',
        'NetAdapterRsc',
        'NetAdapterRss',
        'NetAdapterState',
        'NetBIOS',
        'NetConnectionProfile',
        'NetIPInterface',
        'NetworkTeam',
        'NetworkTeamInterface',
        'ProxySettings',
        'Route',
        'WINSSetting'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')
            # ReleaseNotes of this module
            ReleaseNotes = '## [8.2.0] - 2020-10-16
 
### Changed
 
- IPAddress
  - Improved integration test structure.
 
### Fixed
 
- NetIPInterface
  - Fix ''type mismatch for property'' issue when setting ''AdvertiseDefaultRoute'',
    ''Advertising'', ''AutomaticMetric'', ''Dhcp'', ''DirectedMacWolPattern'', ''EcnMarking'',
    ''ForceArpNdWolPattern'', ''Forwarding'', ''IgnoreDefaultRoutes'', ''ManagedAddressConfiguration'',
    ''NeighborUnreachabilityDetection'', ''OtherStatefulConfiguration'', ''RouterDiscovery'',
 
'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}