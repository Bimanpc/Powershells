Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true |
Select-Object -ExpandProperty IPAddresss