# Define the URL for the OpenSpeedTest server
$speedTestUrl = "https://openspeedtest.com"

# Function to perform the speed test
function Test-InternetSpeed {
    try {
        # Send a web request to the OpenSpeedTest server
        $response = Invoke-WebRequest -Uri $speedTestUrl -UseBasicParsing

        # Parse the response to extract speed test results
        # Note: The actual parsing will depend on the structure of the response from the OpenSpeedTest server
        $downloadSpeed = $response.Content | Select-String -Pattern "Download Speed: (\d+.\d+) Mbps" | ForEach-Object { $_.Matches.Groups[1].Value }
        $uploadSpeed = $response.Content | Select-String -Pattern "Upload Speed: (\d+.\d+) Mbps" | ForEach-Object { $_.Matches.Groups[1].Value }

        # Output the results
        Write-Output "Download Speed: $downloadSpeed Mbps"
        Write-Output "Upload Speed: $uploadSpeed Mbps"
    } catch {
        Write-Error "Failed to perform speed test: $_"
    }
}

# Run the speed test
Test-InternetSpeed
