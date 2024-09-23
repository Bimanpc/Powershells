# Save this script as Get-WhoIsInformation.ps1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String] $APIKey,
    [Parameter(Mandatory = $true)]
    [string[]] $DomainName
)

$responses = @()
$DomainName | ForEach-Object {
    $requestUri = "https://www.whoisxmlapi.com/whoisserver/WhoisService?apiKey=$APIKey&domainName=$_&outputFormat=JSON"
    $responses += Invoke-RestMethod -Method Get -Uri $requestUri
}

$properties = "domainName", "createdDate", "updatedDate", "expiresDate", "registrarName", "contactEmail"
$whoIsInfo = $responses.WhoisRecord | Select-Object -Property $properties
$whoIsInfo | Export-Csv -NoTypeInformation domain-whois.csv
$whoIsInfo | Format-Table
