# Import the necessary assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = "Audio Player by Vasiilis PSAROMATIS"
$form.Width = 400
$form.Height = 200

# Create a button to open a folder dialog
$btnOpenFolder = New-Object Windows.Forms.Button
$btnOpenFolder.Text = "Open Folder"
$btnOpenFolder.Location = New-Object Drawing.Point(20, 20)
$btnOpenFolder.Add_Click({
    $folderBrowser = New-Object Windows.Forms.FolderBrowserDialog
    $result = $folderBrowser.ShowDialog()
    if ($result -eq [Windows.Forms.DialogResult]::OK) {
        # Get the selected folder path
        $folderPath = $folderBrowser.SelectedPath
        # List audio files in the folder (you can customize this part)
        $audioFiles = Get-ChildItem -Path $folderPath -Filter *.mp3
        # Play the first audio file (you'll need a proper audio player library)
        # For simplicity, let's assume you have a function PlayAudioFile
        PlayAudioFile $audioFiles[0].FullName
    }
})

# Add the button to the form
$form.Controls.Add($btnOpenFolder)

# Show the form
$form.ShowDialog()
