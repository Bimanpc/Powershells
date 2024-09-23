# Define the WHOIS server and port
$whoisServer = "whois.arin.net"
$port = 43

# Function to perform WHOIS lookup
function Get-Whois {
    param (
        [string]$ipAddress
    )

    # Create a TCP connection to the WHOIS server
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($whoisServer, $port)
    $networkStream = $tcpClient.GetStream()
    $streamWriter = New-Object System.IO.StreamWriter($networkStream)
    $streamReader = New-Object System.IO.StreamReader($networkStream)

    # Send the IP address to the WHOIS server
    $streamWriter.WriteLine($ipAddress)
    $streamWriter.Flush()

    # Read the response from the WHOIS server
    $response = $streamReader.ReadToEnd()

    # Close the connection
    $streamWriter.Close()
    $streamReader.Close()
    $tcpClient.Close()

    # Return the response
    return $response
}

# Example usage
$ipAddress = "8.8.8.8"
$result = Get-Whois -ipAddress $ipAddress
Write-Output $result
