# Load the XAML GUI
Add-Type -AssemblyName PresentationFramework
$XAML = [System.IO.File]::ReadAllText('NetworkInfoGui.xaml')
$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Define the event handler for the "Get Network Info" button
$Button_GetNetworkInfo_Click = {
    $networkInfo = Get-NetAdapter | Select-Object Name, InterfaceDescription, MacAddress, Status, LinkSpeed
    $networkInfoText.Text = $networkInfo | ForEach-Object {
        "Name: $($_.Name)`r`nDescription: $($_.InterfaceDescription)`r`nMAC Address: $($_.MacAddress)`r`nStatus: $($_.Status)`r`nLink Speed: $($_.LinkSpeed) Mbps`r`n`r`n"
    }
}

$Window.FindName("Button_GetNetworkInfo_Click").Add_Click($Button_GetNetworkInfo_Click)

# Display the GUI
$Window.ShowDialog() | Out-Null
