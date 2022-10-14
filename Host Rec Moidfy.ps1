### Run the script with Admin rights###

#Provide the domain name e.g. bing.com
$domain =read-host "provide the domain name"

#Provide the hostname you want to change the DNS address
$host1= read-host "Provide host name" -ErrorAction SilentlyContinue

#Get the All DNS records
$hostrecords =get-DnsServerResourceRecord -ZoneName $domain|Select-Object -ExpandProperty Hostname

#Compare the hostname with the hostname in the domain
if ($hostrecords -notcontains $host1)
{
Write-Host "$host1 is not found ,choose correct hostname !!!!" -ForegroundColor DarkRed
}

else{ 


#Provide the New DNS record
$record=read-host "Provide the New DNS record"

#If the IP Address in not in correct manner there will be error
if ($record -notlike "*.*.*.*")

{
 write-host  "Provide corrrect IP" -foregroundColor DarkRed
}

else{

#Reads the New DNS record
$NewDNS = get-DnsServerResourceRecord -Name $host1 -ZoneName $domain

#Reads the old DNS record
$OldDNS = get-DnsServerResourceRecord -Name $host1 -ZoneName $domain

#set the new IP Address to host
$NewDNS.RecordData.IPv4Address = [System.Net.IPAddress]::parse($record)

write-host "Changing  host DNS record!!!!" -ForegroundColor DarkYellow
Set-DnsServerResourceRecord -NewInputObject $NewDNS -OldInputObject $OldDNS -ZoneName $domain

Write-host "The DNS record of $host1 is changed to $record" -ForegroundColor DarkCyan

#Shows the DNS record is changed
get-DnsServerResourceRecord -Name $hos1 -ZoneName $domain}}