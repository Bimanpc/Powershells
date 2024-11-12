# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Wi-Fi Manager"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a button to list Wi-Fi networks
$btnListNetworks = New-Object System.Windows.Forms.Button
$btnListNetworks.Text = "List Wi-Fi Networks"
$btnListNetworks.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($btnListNetworks)

# Create a listbox to display the networks
$lbNetworks = New-Object System.Windows.Forms.ListBox
$lbNetworks.Location = New-Object System.Drawing.Point(10, 50)
$lbNetworks.Size = New-Object System.Drawing.Size(360, 150)
$form.Controls.Add($lbNetworks)

# Create a textbox for the Wi-Fi password
$txtPassword = New-Object System.Windows.Forms.TextBox
$txtPassword.Location = New-Object System.Drawing.Point(10, 210)
$txtPassword.Size = New-Object System.Drawing.Size(200, 20)
$txtPassword.PasswordChar = '*'
$txtPassword.PlaceholderText = "Enter Wi-Fi password"
$form.Controls.Add($txtPassword)

# Create a button to connect to the selected network
$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(220, 210)
$form.Controls.Add($btnConnect)

# Function to list Wi-Fi networks
function List-WiFiNetworks {
    $lbNetworks.Items.Clear()
    $networks = netsh wlan show networks | ForEach-Object {
        if ($_ -match "SSID\s+\d+\s*:\s*(.+)") {
            $matches[1]
        }
    }
    foreach ($network in $networks) {
        $lbNetworks.Items.Add($network)
    }
}

# Function to connect to a selected network
function Connect-WiFiNetwork {
    $selectedNetwork = $lbNetworks.SelectedItem
    $password = $txtPassword.Text
    if ($selectedNetwork -and $password) {
        $connectionProfile = @"
<Network>
    <SSIDConfig>
        <SSID>
            <name>$selectedNetwork</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <authentication>WPA2PSK</authentication>
    <encryption>AES</encryption>
    <sharedKey>
        <keyMaterial>$password</keyMaterial>
    </sharedKey>
</Network>
"@
        $profilePath = [System.IO.Path]::GetTempFileName() + ".xml"
        [System.IO.File]::WriteAllText($profilePath, $connectionProfile)
        Start-Process -FilePath "netsh.exe" -ArgumentList "wlan add profile filename=$profilePath" -NoNewWindow -Wait
        Start-Process -FilePath "netsh.exe" -ArgumentList "wlan connect name=$selectedNetwork" -NoNewWindow -Wait
        [System.IO.File]::Delete($profilePath)
        [System.Windows.Forms.MessageBox]::Show("Connected to $selectedNetwork!")
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a network and enter a password.")
    }
}

# Button actions
$btnListNetworks.Add_Click({ List-WiFiNetworks })
$btnConnect.Add_Click({ Connect-WiFiNetwork })

# Show the form
$form.ShowDialog()
