Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sound Settings"
$form.Width = 300
$form.Height = 150

# Create labels
$labelVolume = New-Object System.Windows.Forms.Label
$labelVolume.Text = "Volume:"
$labelVolume.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($labelVolume)

# Create trackbar/slider for volume
$trackBarVolume = New-Object System.Windows.Forms.TrackBar
$trackBarVolume.Minimum = 0
$trackBarVolume.Maximum = 100
$trackBarVolume.Location = New-Object System.Drawing.Point(100, 20)
$trackBarVolume.Width = 150
$form.Controls.Add($trackBarVolume)

# Create a button to apply settings
$buttonApply = New-Object System.Windows.Forms.Button
$buttonApply.Text = "Apply"
$buttonApply.Location = New-Object System.Drawing.Point(110, 80)
$buttonApply.add_Click({
    $volume = $trackBarVolume.Value
    # Adjust sound volume using appropriate PowerShell commands
    # For example, you could use 'Set-Volume' cmdlet or 'nircmd' utility.
    # Example: Invoke-Expression "nircmd.exe setsysvolume $volume"
    # Replace 'nircmd.exe' with the actual path to the executable.
})
$form.Controls.Add($buttonApply)

# Show the form
$form.ShowDialog()
