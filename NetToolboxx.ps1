# Network GUI Script
Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Tools"
$form.Width = 400
$form.Height = 200

# Add a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Choose an action:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($label)

# Add buttons
$buttonPing = New-Object System.Windows.Forms.Button
$buttonPing.Text = "Ping"
$buttonPing.Location = New-Object System.Drawing.Point(20, 50)
$buttonPing.Add_Click({
    # Execute ping command here
    # Example: Test-Connection google.com
})
$form.Controls.Add($buttonPing)

$buttonTracert = New-Object System.Windows.Forms.Button
$buttonTracert.Text = "Tracert"
$buttonTracert.Location = New-Object System.Drawing.Point(120, 50)
$buttonTracert.Add_Click({
    # Execute tracert command here
    # Example: Test-NetConnection google.com -TraceRoute
})
$form.Controls.Add($buttonTracert)

# Show the form
$form.ShowDialog()
