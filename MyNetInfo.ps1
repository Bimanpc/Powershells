Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Information"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create labels
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Network Adapters:"
$form.Controls.Add($label)

# Create a listbox to display network adapter details
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 50)
$listBox.Size = New-Object System.Drawing.Size(360, 200)
$form.Controls.Add($listBox)

# Get network adapter information
$networkAdapters = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 }

foreach ($adapter in $networkAdapters) {
    $listBox.Items.Add("Name: " + $adapter.Name)
    $listBox.Items.Add("Description: " + $adapter.Description)
    $listBox.Items.Add("MAC Address: " + $adapter.MACAddress)
    $listBox.Items.Add("IP Address: " + ($adapter | Get-WmiObject Win32_NetworkAdapterConfiguration).IPAddress[0])
    $listBox.Items.Add("")  # Add a blank line between adapters
}

# Show the form
$form.ShowDialog()
