<#
.SYNOPSIS
Uses Win32_Fan class to return information about fans in a system.

.DESCRIPTION
This script first defines some functions to decode various WMI attributes from binary to text. Then it calls Get-WmiObject to retrieve fan details and formats that information.

.NOTES
File Name: Get-Fan.ps1
Author: Thomas Lee - tfl@psp.co.uk
Requires: PowerShell V2 CTP3

.LINK
Script posted to:
[4](http://pshscripts.blogspot.com/2009/04/win32fan-sample-using-powershell.html)
Original MSDN Page:
[5](http://msdn.microsoft.com/en-us/library/aa394146).aspx)

.EXAMPLE
Left as an exercise for the viewer.
#>

# Functions to decode details
function FanAvailability {
    param ($value)
    switch ($value) {
        1 { "Other" }
        2 { "Unknown" }
        3 { "Running on full power" }
        4 { "Warning" }
        5 { "In Test" }
        6 { "Not Applicable" }
        7 { "Power Off" }
        8 { "Off Line" }
        9 { "Off Duty" }
        10 { "Degraded" }
        11 { "Not Installed" }
        12 { "Install Error" }
        13 { "Power Save - Unknown" }
        14 { "Power Save - Low Power Mode" }
        15 { "Power Save - Standby" }
        16 { "Power Cycle" }
        17 { "Power Save - Warning" }
        default { "NOT SET" }
    }
}

function ConfigManagerErrorCode {
    param ($value)
    switch ($value) {
        # ... (truncated for brevity)
        24 { "Device is not present, not working properly, or does not have all of its drivers installed" }
        25 { "Windows is still setting up the device" }
        26 { "Windows is still setting up the device" }
        # ... (truncated for brevity)
    }
}

# Retrieve fan details
$fans = Get-WmiObject Win32_Fan

# Display fan information
foreach ($fan in $fans) {
    Write-Host "Fan Availability: $(FanAvailability $fan.Availability)"
    Write-Host "Config Manager Error Code: $(ConfigManagerErrorCode $fan.ConfigManagerErrorCode)"
    Write-Host "Fan Name: $($fan.Name)"
    Write-Host "Status: $($fan.Status)"
    Write-Host "----------------------------------------"
}
