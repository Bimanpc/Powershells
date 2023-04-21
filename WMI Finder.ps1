## Query the Win32_OperatingSystem CIM instance on both the serv1 and serv2 computers
Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName Serv1,Serv2 |`
## Limit the output to only a few select propeties
Select-Object -Property BuildNumber,BuildType,OSType,ServicePackMajorVersion,ServicePackMinorVersion | `
## Send each CIM instance object to a CSV file called C:\Folders\Computers.csv
Export-CSV C:\Folder\Computers.csv -NoTypeInformation -Encoding UTF8 -Verbose