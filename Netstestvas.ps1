# PowerShell Speed Test Script

# Specify the target host for the speed test
$targetHost = "www.google.com"

# Number of pings to send
$pingCount = 10

# Perform the speed test using Test-Connection
$results = Test-Connection -ComputerName $targetHost -Count $pingCount

# Calculate average round-trip time
$averageRTT = ($results | Measure-Object ResponseTime -Average).Average

# Display the results
Write-Host "Speed test results for $targetHost:"
Write-Host "  Average Round-Trip Time: $($averageRTT)ms"
