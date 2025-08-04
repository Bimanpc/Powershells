# USB Format PowerShell Script
# Run as Administrator

Write-Host "Listing all removable drives..."
$drives = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq 'USB' }

if ($drives.Count -eq 0) {
    Write-Host "No USB drives detected. Please insert a USB device."
    exit
}

foreach ($drive in $drives) {
    Write-Host "Found USB Drive: $($drive.Model)"
    $partitions = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($drive.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
    foreach ($partition in $partitions) {
        $volumes = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
        foreach ($volume in $volumes) {
            Write-Host "`nDrive Letter: $($volume.DeviceID)"
            Write-Host "Volume Name: $($volume.VolumeName)"
            Write-Host "File System: $($volume.FileSystem)"
            Write-Host "Size (GB): $([math]::round($volume.Size / 1GB, 2))"
        }
    }
}

$driveLetter = Read-Host "`nEnter the drive letter of the USB to format (e.g., E)"
$confirmation = Read-Host "Type 'YES' to confirm formatting $driveLetter"

if ($confirmation -eq "YES") {
    Write-Host "Formatting drive $driveLetter..."
    Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "USBFormatted" -Confirm:$false
    Write-Host "Drive $driveLetter formatted successfully."
} else {
    Write-Host "Formatting canceled."
}
