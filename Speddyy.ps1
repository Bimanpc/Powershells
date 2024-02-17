Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Network 2.0 Speed Test'

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10,10)
$button.Size = New-Object System.Drawing.Size(75,23)
$button.Text = 'Start Test'
$form.Controls.Add($button)

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,40)
$label.Size = New-Object System.Drawing.Size(280,20)
$form.Controls.Add($label)

# Handle button click event
$button.Add_Click({
    $ping = New-Object System.Net.NetworkInformation.Ping
    $result = $ping.Send('google.com')
    $label.Text = "Roundtrip time: $($result.RoundtripTime) ms"
})

# Show the form
$form.ShowDialog()
