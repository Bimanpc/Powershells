Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Accessible Media Player"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Create Play button
$playButton = New-Object System.Windows.Forms.Button
$playButton.Text = "Play"
$playButton.Location = New-Object System.Drawing.Point(50, 50)
$playButton.Size = New-Object System.Drawing.Size(100, 50)
$playButton.Add_Click({ $player.controls.play() })
$form.Controls.Add($playButton)

# Create Stop button
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop"
$stopButton.Location = New-Object System.Drawing.Point(200, 50)
$stopButton.Size = New-Object System.Drawing.Size(100, 50)
$stopButton.Add_Click({ $player.controls.stop() })
$form.Controls.Add($stopButton)

# Create Open File button
$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = "Open File"
$openButton.Location = New-Object System.Drawing.Point(50, 120)
$openButton.Size = New-Object System.Drawing.Size(250, 30)
$openButton.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "Audio Files|*.mp3;*.wav;*.wma"
    if ($fileDialog.ShowDialog() -eq "OK") {
        $player.URL = $fileDialog.FileName
        $player.controls.play()
    }
})
$form.Controls.Add($openButton)

# Create Media Player ActiveX object
$player = New-Object -ComObject WMPLib.WindowsMediaPlayer

# Set keyboard shortcuts for accessibility
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($sender, $e)
    switch ($e.KeyCode) {
        "P" { $player.controls.play() }
        "S" { $player.controls.stop() }
        "O" { $openButton.PerformClick() }
    }
})

# Show form
$form.ShowDialog()
