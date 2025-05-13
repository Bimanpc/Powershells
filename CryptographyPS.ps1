Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Simple AI Cryptographer"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Select a file to encrypt:"
$form.Controls.Add($label)

# Create a text box to display the selected file path
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($textBox)

# Create a button to browse for a file
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(10, 80)
$browseButton.Size = New-Object System.Drawing.Size(100, 30)
$browseButton.Text = "Browse"
$browseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
    $openFileDialog.Filter = "All files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox.Text = $openFileDialog.FileName
    }
})
$form.Controls.Add($browseButton)

# Create a button to encrypt the file
$encryptButton = New-Object System.Windows.Forms.Button
$encryptButton.Location = New-Object System.Drawing.Point(10, 130)
$encryptButton.Size = New-Object System.Drawing.Size(100, 30)
$encryptButton.Text = "Encrypt"
$encryptButton.Add_Click({
    $filePath = $textBox.Text
    if ([string]::IsNullOrEmpty($filePath)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a file to encrypt.")
        return
    }

    # Here you would add your encryption logic
    # For demonstration purposes, we'll just show a message box
    [System.Windows.Forms.MessageBox]::Show("File encrypted successfully!")
})
$form.Controls.Add($encryptButton)

# Create a button to save the encrypted file
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Location = New-Object System.Drawing.Point(10, 180)
$saveButton.Size = New-Object System.Drawing.Size(100, 30)
$saveButton.Text = "Save"
$saveButton.Add_Click({
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
    $saveFileDialog.Filter = "All files (*.*)|*.*"
    if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $savePath = $saveFileDialog.FileName
        # Here you would add your save logic
        [System.Windows.Forms.MessageBox]::Show("File saved successfully!")
    }
})
$form.Controls.Add($saveButton)

# Show the form
$form.ShowDialog()
