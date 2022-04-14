# Show total physical memory in GB
# Note that Get-PCInfo may take a while getting "all" data
[int]( ( Get-ComputerInfo ).CsTotalPhysicalMemory / 1GB )

# or, faster:

[int]( ( Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum ).Sum / 1GB )

# or:

$shell = New-Object -ComObject Shell.Application
[int] ( $shell.GetSystemInformation( 'PhysicalMemoryInstall' ) / 1GB )