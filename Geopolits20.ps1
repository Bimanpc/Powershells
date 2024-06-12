function Get-ComputerGeoLocation {
    # Windows Location API
    $mylocation = New-Object -ComObject LocationDisp.LatLongReportFactory

    # Get Status
    $mylocationstatus = $mylocation.status

    if ($mylocationstatus -eq "4") {
        # Get Latitude and Longitude from LatlongReport property
        $latitude = $mylocation.LatLongReport.Latitude
        $longitude = $mylocation.LatLongReport.Longitude

        if ($latitude -ne $null -or $longitude -ne $Null) {
            # Retrieve Geolocation from Google Geocoding API
            $webClient = New-Object System.Net.WebClient
            $url = "https://maps.googleapis.com/maps/api/geocode/xml?latlng=$latitude,$longitude&sensor=true"
            $locationinfo = $webClient.DownloadString($url)
            $doc = [xml]$locationinfo

            if ($doc.GeocodeResponse.status -eq "OK") {
                $street_address = $doc.GeocodeResponse.result | Select-Object -Property formatted_address, Type | Where-Object -Property Type -eq "street_address"
                $geoobject = New-Object -TypeName PSObject
                $geoobject | Add-Member -MemberType NoteProperty -Name Address -Value $street_address.formatted_address
                $geoobject | Add-Member -MemberType NoteProperty -Name latitude -Value $mylocation.LatLongReport.Latitude
                $geoobject | Add-Member -MemberType NoteProperty -Name longitude -Value $mylocation.LatLongReport.longitude
                $geoobject | Format-List
            } else {
                Write-Warning "Request failed, unable to retrieve Geo location information from Geocoding API"
            }
        } else {
            Write-Warning "Latitude or Longitude data missing"
        }
    } else {
        switch ($mylocationstatus) {
            0 { $mylocationstatuserr = "Report not supported" }
            1 { $mylocationstatuserr = "Error" }
            2 { $mylocationstatuserr = "Access denied" }
            3 { $mylocationstatuserr = "Initializing" }
            4 { $mylocationstatuserr = "Running" }
        }

        if ($mylocationstatus -eq "3") {
            Write-Host "Windows Location platform is $mylocationstatuserr"
            Start-Sleep -Seconds 5
            Get-ComputerGeoLocation
        } else {
            Write-Warning "Windows Location platform: Status: $mylocationstatuserr"
        }
    }
}

# Call the function
Get-ComputerGeoLocation
