$ramSpeed = Get-WmiObject -Class Win32_PhysicalMemory | ForEach-Object {
    [math]::Round($_.Speed / 1000, 2)
}

Write-Host "RAM Speed: ${ramSpeed} MHz"
