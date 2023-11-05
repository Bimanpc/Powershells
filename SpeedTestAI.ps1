# Start measuring time
$startTime = Get-Date

# Your AI task or computation
$Result = 0
for ($i = 1; $i -le 1000000; $i++) {
    $Result += $i
}

# End measuring time
$endTime = Get-Date

# Calculate the elapsed time
$elapsedTime = $endTime - $startTime

# Display the result and execution time
Write-Host "Result: $Result"
Write-Host "Execution Time: $elapsedTime"
