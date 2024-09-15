# Define the IP address you want to look up
$ipAddress = "8.8.8.8"

# Define the API endpoint and your API key (replace with your actual API key)
$apiKey = "$ curl https://api.ipgeolocation.io/ipgeo?ip=2a02:587:7e3f:4200:3d32:eeb2:6f57:8baa"
$apiUrl = "https://api.ipgeolocation.io/ipgeo?apiKey=$apiKey&ip=$ipAddress"

# Make the API request
$response = Invoke-RestMethod -Uri $apiUrl -Method Get

# Display the geolocation information
Write-Output "IP Address: $($response.ip)"
Write-Output "Country: $($response.country_name)"
Write-Output "Region: $($response.state_prov)"
Write-Output "City: $($response.city)"
Write-Output "Latitude: $($response.latitude)"
Write-Output "Longitude: $($response.longitude)"
Write-Output "ISP: $($response.isp)"
