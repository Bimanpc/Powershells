# Import necessary namespaces
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WiFi Manager"
$form.Size = New-Object System.Drawing.Size(300,400)
$form.StartPosition = "CenterScreen"

# Create a ListBox for displaying SSIDs
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(260,260)
$listBox.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($listBox)

# Create a TextBox for entering the SSID
$ssidTextBox = New-Object System.Windows.Forms.TextBox
$ssidTextBox.Location = New-Object System.Drawing.Point(10,280)
$ssidTextBox.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($ssidTextBox)

# Create a Button for connecting to the SSID
$connectButton = New-Object System.Windows.Forms.Button
$connectButton.Text = "Connect"
$connectButton.Location = New-Object System.Drawing.Point(10,310)
$connectButton.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($connectButton)

# Function to refresh the SSID list
function Refresh-SSIDList {
    $listBox.Items.Clear()
    $networks = netsh wlan show networks
    $networks | ForEach-Object {
        if ($_ -match 'SSID\s+:\s+(.+)$') {
            $listBox.Items.Add($matches[1])
        }
    }
}

# Event handler for the Connect button
$connectButton.Add_Click({
    $selectedSSID = $ssidTextBox.Text
    if ($selectedSSID) {
        netsh wlan connect name=$selectedSSID
        [System.Windows.Forms.MessageBox]::Show("Connecting to $selectedSSID")
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter an SSID")
    }
})

# Initialize the form
$form.Add_Shown({Refresh-SSIDList})
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
