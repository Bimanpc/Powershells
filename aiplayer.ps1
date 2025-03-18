# Load the required assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "VLC Fork Player with AI"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create a button to open a file
$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = "Open File"
$openButton.Location = New-Object System.Drawing.Point(20, 20)
$openButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Media Files (*.mp4;*.mkv;*.avi)|*.mp4;*.mkv;*.avi|All Files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $filePath = $openFileDialog.FileName
        # Start VLC with the selected file
        Start-Process "vlc.exe" -ArgumentList $filePath
    }
})
$form.Controls.Add($openButton)

# Create a button to exit the application
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Location = New-Object System.Drawing.Point(20, 60)
$exitButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($exitButton)

# Show the form
$form.ShowDialog()
