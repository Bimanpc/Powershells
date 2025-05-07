Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Railway Geolocation Tracker"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Railway Geolocation Tracker"
$label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

# Create a text box for displaying location
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 60)
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$textBox.Multiline = $true
$textBox.ReadOnly = $true
$form.Controls.Add($textBox)

# Create a button to simulate tracking
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 100)
$button.Size = New-Object System.Drawing.Size(360, 30)
$button.Text = "Start Tracking"
$button.Add_Click({
    $textBox.Text = "Tracking railway location... (simulated)"
})
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
