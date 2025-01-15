# Import necessary .NET assemblies for GUI creation
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Wi-Fi Manager"
$form.Size = New-Object System.Drawing.Size(300,300)

# Create a dropdown for available Wi-Fi networks
$networks = New-Object System.Windows.Forms.ComboBox
$networks.Location = New-Object System.Drawing.Point(10,20)
$networks.Size = New-Object System.Drawing.Size(260,40)
$networks.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($networks)

# Create a button to refresh Wi-Fi networks
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(10,70)
$refreshButton.Size = New-Object System.Drawing.Size(260,30)
$refreshButton.Text = "Refresh Networks"
$form.Controls.Add($refreshButton)

# Create a button to connect to the selected network
$connectButton = New-Object System.Windows.Forms.Button
$connectButton.Location = New-Object System.Drawing.Point(10,110)
$connectButton.Size = New-Object System.Drawing.Size(260,30)
$connectButton.Text = "Connect"
$form.Controls.Add($connectButton)

# Event handler to refresh available Wi-Fi networks
$refreshButton.Add_Click({
    $networks.Items.Clear()
    $wifiNetworks = netsh wlan show networks | Select-String "SSID" | ForEach-Object { $_.ToString().Trim().Substring(9) }
    $wifiNetworks | ForEach-Object { $networks.Items.Add($_) }
})

# Event handler to connect to the selected network
$connectButton.Add_Click({
    $selectedNetwork = $networks.SelectedItem
    if ($selectedNetwork) {
        $password = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Password for $selectedNetwork", "Wi-Fi Password", "")
        netsh wlan connect name=$selectedNetwork key=$password
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Please select a Wi-Fi network.")
    }
})

# Show the form
$form.Add_Shown({ $refreshButton.PerformClick() })
$form.ShowDialog()
