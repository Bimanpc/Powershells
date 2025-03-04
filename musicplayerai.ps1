Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "AIMP-Like Music Player"
$Form.Size = New-Object System.Drawing.Size(400, 300)
$Form.StartPosition = "CenterScreen"

# Create OpenFileDialog to select music files
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "Audio Files|*.mp3;*.wav;*.wma;*.aac"
$OpenFileDialog.Multiselect = $false

# Create the Windows Media Player COM object
$WMP = New-Object -ComObject WMPlayer.OCX

# Create buttons
$BtnOpen = New-Object System.Windows.Forms.Button
$BtnOpen.Text = "Open"
$BtnOpen.Location = New-Object System.Drawing.Point(30, 200)
$BtnOpen.Add_Click({
    if ($OpenFileDialog.ShowDialog() -eq "OK") {
        $WMP.URL = $OpenFileDialog.FileName
    }
})

$BtnPlay = New-Object System.Windows.Forms.Button
$BtnPlay.Text = "Play"
$BtnPlay.Location = New-Object System.Drawing.Point(120, 200)
$BtnPlay.Add_Click({ $WMP.controls.play() })

$BtnPause = New-Object System.Windows.Forms.Button
$BtnPause.Text = "Pause"
$BtnPause.Location = New-Object System.Drawing.Point(210, 200)
$BtnPause.Add_Click({ $WMP.controls.pause() })

$BtnStop = New-Object System.Windows.Forms.Button
$BtnStop.Text = "Stop"
$BtnStop.Location = New-Object System.Drawing.Point(300, 200)
$BtnStop.Add_Click({ $WMP.controls.stop() })

# Add controls to the form
$Form.Controls.Add($BtnOpen)
$Form.Controls.Add($BtnPlay)
$Form.Controls.Add($BtnPause)
$Form.Controls.Add($BtnStop)

# Run the application
$Form.ShowDialog()
