# Function to clean temporary files
Function Clean-TemporaryFiles {
    Remove-Item -Path "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
}

# Function to clean Recycle Bin
Function Empty-RecycleBin {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.Namespace(0xA)
    $recycleBin.Items() | ForEach-Object { $_.InvokeVerb("Delete") }
}

# Function to clean Windows Update cache
Function Clean-WindowsUpdateCache {
    Stop-Service -Name wuauserv
    Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Force -Recurse -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv
}

# Clean temporary files
Clean-TemporaryFiles

# Empty Recycle Bin
Empty-RecycleBin

# Clean Windows Update cache
Clean-WindowsUpdateCache

Write-Output "Disk cleanup completed successfully."
