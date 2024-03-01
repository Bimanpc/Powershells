# Check CPU temperature
function Get-CPUTemperature {
    $wmi = Get-WmiObject -Namespace "root\cimv2" -Class Win32_PerfFormattedData_Counters_ThermalZoneInformation
    $temperature = $wmi.Temperature / 10 # Convert to degrees Celsius
    Write-Host "CPU Temperature: $temperature°C"
}

Get-CPUTemperature
