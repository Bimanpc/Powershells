Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "IP Address Viewer"
$form.Size = New-Object System.Drawing.Size(300, 100)
$form.StartPosition = "CenterScreen"

# Create a label to display the IP address
$label = New-Object System.Windows.Forms.Label
$label.Text = "Your IP Address:"
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(150, 20)
$form.Controls.Add($label)

# Create a textbox to display the IP address
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(160, 10)
$textBox.Size = New-Object System.Drawing.Size(120, 20)
$textBox.ReadOnly = $true
$form.Controls.Add($textBox)

# Function to get the IP address
Function Get-IPAddress {
    $ipAddress = (Test-Connection -ComputerName (hostname) -Count 1).IPv4Address.IPAddressToString
    $textBox.Text = $ipAddress
}

# Call the function to get the IP address
Get-IPAddress

# Show the form
$form.ShowDialog() | Out-Null
