# Add required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Simple Radio Player"
$form.Size = New-Object System.Drawing.Size(300, 200)

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Radio URL:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a textbox for URL input
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$form.Controls.Add($textBox)

# Create a play button
$playButton = New-Object System.Windows.Forms.Button
$playButton.Text = "Play"
$playButton.Location = New-Object System.Drawing.Point(10, 80)
$form.Controls.Add($playButton)

# Create a stop button
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop"
$stopButton.Location = New-Object System.Drawing.Point(100, 80)
$form.Controls.Add($stopButton)

# Add event handlers for buttons
$playButton.Add_Click({
    $url = $textBox.Text
    if ($url) {
        $player = New-Object System.Windows.Media.MediaPlayer
        $player.Open([Uri]$url)
        $player.Play()
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid URL.")
    }
})

$stopButton.Add_Click({
    if ($player) {
        $player.Stop()
    }
})

# Show the form
$form.ShowDialog()
