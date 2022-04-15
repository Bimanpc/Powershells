<#PSScriptInfo
 
.VERSION 2022
 
.GUID 07e4ef9f-8341-4dc4-bc73-fc277eb6b4e6
 
.AUTHOR Billieye
#>

<#
.SYNOPSIS
Installs the latest Windows 10 quality updates.
.DESCRIPTION
This script uses the PSWindowsUpdate module to install the latest cumulative update for Windows 10.
.EXAMPLE
.\UpdateOS.ps1
#>

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}

# Create a tag file just so Intune knows this was installed
if (-not (Test-Path "$($env:ProgramData)\Microsoft\UpdateOS"))
{
    Mkdir "$($env:ProgramData)\Microsoft\UpdateOS"
}
Set-Content -Path "$($env:ProgramData)\Microsoft\UpdateOS\UpdateOS.ps1.tag" -Value "Installed"

# Start logging
Start-Transcript "$($env:ProgramData)\Microsoft\UpdateOS\UpdateOS.log"

# Main logic
$needReboot = $false
Write-Host "Installsssss.. updates."

# Load module from PowerShell Gallery
$null = Install-PackageProvider -Name NuGet -Force
$null = Install-Module PSWindowsUpdate -Force
Import-Module PSWindowsUpdate

# Install all available updates
Get-WindowsUpdate -Install -IgnoreUserInput -AcceptAll -MicrosoftUpdate -IgnoreReboot | Select Title, KB, Result | Format-Table
$needReboot = (Get-WURebootStatus).RebootRequired

# Specify return code
if ($needReboot)
{
    # Set return code 3010. As long as this happens during device ESP, the computer will automatically reboot at the end of device ESP.
    Write-Host "Reboot is need."
    Stop-Transcript
    Exit 3010
    # Exit 1641
}
else
{
    Write-Host "Reboot isnt  required."
    Stop-Transcript
    Exit 0
}
