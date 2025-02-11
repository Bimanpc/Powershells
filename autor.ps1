# Load the required assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Media

# Create the main form
$form = New-Object Windows.Forms.Form
$form.Text = "Simple Car Radio Player"
$form.Size = New-Object Drawing.Size(300, 200)

# Create a label
$label = New-Object Windows.Forms.Label
$label.Text = "Car Radio Player"
$label.AutoSize = $true
$label.Location = New-Object Drawing.Point(90, 20)
$form.Controls.Add($label)

# Create a Play button
$playButton = New-Object Windows.Forms.Button
$playButton.Text = "Play"
$playButton.Location = New-Object Drawing.Point(50, 70)
$form.Controls.Add($playButton)

# Create a Stop button
$stopButton = New-Object Windows.Forms.Button
$stopButton.Text = "Stop"
$stopButton.Location = New-Object Drawing.Point(150, 70)
$form.Controls.Add($stopButton)

# Create a Volume control
$volumeControl = New-Object Windows.Forms.TrackBar
$volumeControl.Minimum = 0
$volumeControl.Maximum = 100
$volumeControl.Value = 50
$volumeControl.TickFrequency = 10
$volumeControl.Location = New-Object Drawing.Point(50, 110)
$form.Controls.Add($volumeControl)

# Load the sound file (you need to specify a valid file path)
$soundPlayer = New-Object System.Media.SoundPlayer
$soundPlayer.SoundLocation = "path\to\your\audiofile.wav"

# Play button event
$playButton.Add_Click({
    $soundPlayer.Play()
})

# Stop button event
$stopButton.Add_Click({
    $soundPlayer.Stop()
})

# Volume control event (Note: System.Media.SoundPlayer does not support volume control. This is for demonstration.)
$volumeControl.Add_Scroll({
    Write-Host "Volume: $($volumeControl.Value)"
})

# Show the form
$form.Add_Shown({ $form.Activate() })
[Windows.Forms.Application]::Run($form)
