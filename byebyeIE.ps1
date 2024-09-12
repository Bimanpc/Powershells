# PowerShell script to remove Internet Explorer
# Check if IE is installed
$check = Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -eq "Internet-Explorer-Optional-amd64"}

if ($check.State -ne "Disabled") {
    # Remove Internet Explorer
    Disable-WindowsOptionalFeature -FeatureName Internet-Explorer-Optional-amd64 -Online -NoRestart | Out-Null
    Write-Output "Internet Explorer has been removed. Please restart your computer to complete the process."
} else {
    Write-Output "Internet Explorer is already removed or not installed."
}
