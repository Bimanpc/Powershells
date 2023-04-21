Function Get-FixedDisk {
    [CmdletBinding()]
    # This param() block indicates start of parameters declaration
    param (
        <# 
            This parameter accepts the name of the target computer.
            It is also set to mandatory so that the function does not execute without specifying the value.
        #>
        [Parameter(Mandatory)]
        [string]$Computer
    )
    <#
        WMI query command which gets the list of all logical disks and saves the results to a variable named $DiskInfo
    #>
    $DiskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter 'DriveType=3'
   $DiskInfo
}