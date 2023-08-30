# Get CPU information
$cpuInfo = Get-WmiObject Win32_Processor

# Display CPU information
Write-Host "CPU Manufacturer: $($cpuInfo.Manufacturer)"
Write-Host "CPU Model: $($cpuInfo.Name)"
Write-Host "Number of Cores: $($cpuInfo.NumberOfCores)"
Write-Host "Number of Logical Processors: $($cpuInfo.NumberOfLogicalProcessors)"
Write-Host "Max Clock Speed: $($cpuInfo.MaxClockSpeed) MHz"
