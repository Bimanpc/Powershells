# Load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Security Alarm Control Panel"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Create an "Arm Alarm" button
$armButton = New-Object System.Windows.Forms.Button
$armButton.Text = "Arm Alarm"
$armButton.Location = New-Object System.Drawing.Point(50, 50)
$armButton.Size = New-Object System.Drawing.Size(75, 30)
$armButton.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Alarm Armed")
})

# Create a "Disarm Alarm" button
$disarmButton = New-Object System.Windows.Forms.Button
$disarmButton.Text = "Disarm Alarm"
$disarmButton.Location = New-Object System.Drawing.Point(150, 50)
$disarmButton.Size = New-Object System.Drawing.Size(75, 30)
$disarmButton.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Alarm Disarmed")
})

# Add buttons to the form
$form.Controls.Add($armButton)
$form.Controls.Add($disarmButton)

# Show the form
$form.ShowDialog()
