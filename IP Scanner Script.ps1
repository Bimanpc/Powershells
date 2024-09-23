# Save this script as IPScanner.ps1

param (
    [string]$startIP = "192.168.1.1",
    [string]$endIP = "192.168.1.254"
)

function Test-IP {
    param (
        [string]$ip
    )
    try {
        $ping = Test-Connection -ComputerName $ip -Count 1 -ErrorAction Stop
        if ($ping.StatusCode -eq 0) {
            Write-Output "$ip is up"
        }
    } catch {
        Write-Output "$ip is down"
    }
}

$start = [System.Net.IPAddress]::Parse($startIP)
$end = [System.Net.IPAddress]::Parse($endIP)
$range = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($start.GetAddressBytes(), 0))..[System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($end.GetAddressBytes(), 0))

foreach ($ip in $range) {
    $currentIP = [System.Net.IPAddress]::Parse([BitConverter]::GetBytes([System.Net.IPAddress]::HostToNetworkOrder($ip)))
    Test-IP -ip $currentIP.ToString()
}
