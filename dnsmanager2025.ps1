# Define the DNS server and zone
$dnsServer = "YourDNSServer"
$zoneName = "YourZoneName"

# Function to add a DNS A record
function Add-DnsARecord {
    param (
        [string]$recordName,
        [string]$recordIP
    )
    
    Add-DnsServerResourceRecordA -Name $recordName -ZoneName $zoneName -IPv4Address $recordIP -ComputerName $dnsServer
}

# Function to remove a DNS record
function Remove-DnsRecord {
    param (
        [string]$recordName
    )
    
    Remove-DnsServerResourceRecord -Name $recordName -ZoneName $zoneName -ComputerName $dnsServer
}

# Function to update a DNS A record
function Update-DnsARecord {
    param (
        [string]$recordName,
        [string]$newRecordIP
    )
    
    Set-DnsServerResourceRecord -Name $recordName -ZoneName $zoneName -NewIPAddress $newRecordIP -ComputerName $dnsServer
}

# Example usage
Add-DnsARecord -recordName "test" -recordIP "192.168.1.100"
Remove-DnsRecord -recordName "test"
Update-DnsARecord -recordName "test" -newRecordIP "192.168.1.101"
