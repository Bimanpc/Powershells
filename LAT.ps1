Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Latency Meter"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(380, 30)
$label.Text = "Network Latency Measurement"
$form.Controls.Add($label)

# Create a button for WiFi latency
$wifiButton = New-Object System.Windows.Forms.Button
$wifiButton.Location = New-Object System.Drawing.Point(10, 60)
$wifiButton.Size = New-Object System.Drawing.Size(180, 30)
$wifiButton.Text = "Measure WiFi Latency"
$wifiButton.Add_Click({
    $latency = Measure-Command { ping -n 10 8.8.8.8 } | Select-Object -ExpandProperty TotalMilliseconds
    $latency = $latency / 10
    [System.Windows.Forms.MessageBox]::Show("WiFi Latency: $latency ms")
})
$form.Controls.Add($wifiButton)

# Create a button for 5G latency
$fiveGButton = New-Object System.Windows.Forms.Button
$fiveGButton.Location = New-Object System.Drawing.Point(210, 60)
$fiveGButton.Size = New-Object System.Drawing.Size(180, 30)
$fiveGButton.Text = "Measure 5G Latency"
$fiveGButton.Add_Click({
    $latency = Measure-Command { ping -n 10 8.8.8.8 } | Select-Object -ExpandProperty TotalMilliseconds
    $latency = $latency / 10
    [System.Windows.Forms.MessageBox]::Show("5G Latency: $latency ms")
})
$form.Controls.Add($fiveGButton)

# Show the form
$form.ShowDialog()
