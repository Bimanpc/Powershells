Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "5G Latency Meter"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "5G Latency Measurement"
$label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

# Create a text box for displaying latency
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 60)
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($textBox)

# Create a button to measure latency
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 100)
$button.Size = New-Object System.Drawing.Size(360, 30)
$button.Text = "Measure Latency"
$button.Add_Click({
    # Simulate latency measurement
    $latency = Measure-Command { Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100) }.TotalMilliseconds
    $textBox.Text = "Latency: $latency ms"
})
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
