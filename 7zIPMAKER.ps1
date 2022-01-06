@{
GUID = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'
Author = 'PCTECHGREU'
Description = 'Powershell module for creating and extracting 7-Zip archives'
CompanyName = 'N/A'
Copyright = '2022'
DotNetFrameworkVersion = '4.7.2'
ModuleVersion = '2.1.0'
PowerShellVersion = '5.0'
PrivateData = @{
    PSData = @{
        Tags = @('powershell', '7zip', '7-zip', 'zip', 'archive', 'extract', 'compress', 'PSEdition_Core', 'PSEdition_Desktop', 'Windows')
        RequireLicenseAcceptance = $false
        PreRelease = ''
        # ReleaseNotes = ''
    } # End of PSData hashtable
}

NestedModules = @("7Zip4PowerShell.dll")
CmdletsToExport = @(
    "Expand-7Zip",
    "Compress-7Zip",
    "Get-7Zip",
    "Get-7ZipInformation")
}