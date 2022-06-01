Get-Content C:\servers.txt | ForEach-Object {
    $service = Get-WmiObject Win32_Service -Filter 'Name="wuauserv"' -ComputerName $_ -Ea 0
	if ($service)
	{
		if ($service.StartMode -ne "Disabled")
		{
			$result = $service.ChangeStartMode("Disabled").ReturnValue
			if($result)
			{
				"Failed to disable 'wuauserv' service on $_. The return value was $result."
			}
			else {"Success to disable the 'wuauserv' service on $_."}
			
			if ($service.State -eq "Running")
			{
				$result = $service.StopService().ReturnValue
				if ($result)
				{
					"Failed  stop ' 'wuauserv' service on $_. The return value was $result."
				}
				else {"Success to stop the 'wuauserv' service on $_."}
			}
		}
		else {"The 'wuauserv' service on $_ is already disabled."}
	}
	else {"Failed to retrieve the service 'wuauserv' from $_."}
}