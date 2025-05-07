Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Phone Tracking App"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Phone Tracking Application"
$form.Controls.Add($label)

# Create a text box for entering phone number
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$textBox.Size = New-Object System.Drawing.Size(260, 20)
$form.Controls.Add($textBox)

# Create a button to trigger tracking
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 80)
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Text = "Track"
$button.Add_Click({
    $phoneNumber = $textBox.Text
    [System.Windows.Forms.MessageBox]::Show("Tracking functionality would be implemented here for $phoneNumber.")
})
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
