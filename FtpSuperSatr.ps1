@{
    AliasesToExport        = @('Get-FTPDirectory', 'Get-FTPFile', 'Get-SFTPFile', 'Add-FTPDirectory', 'Add-FTPFile', 'Add-SFTPFile', 'Start-FXPDirectory', 'Start-FXPFile')
    Author                 = 'Billieye'
    CmdletsToExport        = @()
    CompanyName            = 'PCTECHGREU'
    CompatiblePSEditions   = @('Desktop', 'Core')
    Copyright              = '(c)2022. All rights reserved.'
    Description            = 'Module which allows ftp, ftps, sftp file transfers with advanced features. It also allows to transfer files and directorires between servers using fxp protocol. As a side feature it allows to conenct to SSH and executes commands on it. '
    DotNetFrameworkVersion = '4.7.2'
    FunctionsToExport      = @('Compare-FTPFile', 'Connect-FTP', 'Connect-SFTP', 'Connect-SSH', 'Disconnect-FTP', 'Disconnect-SFTP', 'Get-FTPChecksum', 'Get-FTPChmod', 'Get-FTPList', 'Get-SFTPList', 'Move-FTPDirectory', 'Move-FTPFile', 'Receive-FTPDirectory', 'Receive-FTPFile', 'Receive-SFTPFile', 'Remove-FTPDirectory', 'Remove-FTPFile', 'Remove-SFTPFile', 'Rename-FTPFile', 'Rename-SFTPFile', 'Request-FTPConfiguration', 'Send-FTPDirectory', 'Send-FTPFile', 'Send-SFTPFile', 'Send-SSHCommand', 'Set-FTPChmod', 'Set-FTPOption', 'Set-FTPTracing', 'Start-FXPDirectoryTransfer', 'Start-FXPFileTransfer', 'Test-FTPDirectory', 'Test-FTPFile')
    GUID                   = '7d61db15-9efe-41d1-a1c0-81d738975dec'
    ModuleVersion          = '0.0.11'
    PowerShellVersion      = '5.1'
    PrivateData            = @{
        PSData = @{
            Tags       = @('Windows', 'Linux', 'MacOs', 'ftp', 'sftp', 'ftps', 'scp', 'winscp', 'ssh') }
    }
    RootModule             = 'Transferetto.psm1'
    ScriptsToProcess       = @('Transferetto.Libraries.ps1')
}
# SIG # Begin signature block
# MIIhjgYJKoZIhvcNAQcCoIIhfzCCIXsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# teBTwt/ekLCgq2bfy6Z2YkZOOTyMjDyTOGC0Zwvwjew5XiVz2fXrbFdwiU2ACJ3J
# h2s=
# SIG # End signature block
