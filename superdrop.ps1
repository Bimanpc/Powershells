Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Airdrop-like App"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select a file to transfer:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($label)

# Create a textbox to display the selected file path
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$textBox.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($textBox)

# Create a button to browse for a file
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(320, 50)
$browseButton.Size = New-Object System.Drawing.Size(60, 20)
$form.Controls.Add($browseButton)

# Create a button to transfer the file
$transferButton = New-Object System.Windows.Forms.Button
$transferButton.Text = "Transfer"
$transferButton.Location = New-Object System.Drawing.Point(10, 80)
$transferButton.Size = New-Object System.Drawing.Size(370, 30)
$form.Controls.Add($transferButton)

# Create a label to display the status
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = ""
$statusLabel.Location = New-Object System.Drawing.Point(10, 120)
$statusLabel.Size = New-Object System.Drawing.Size(370, 20)
$form.Controls.Add($statusLabel)

# Event handler for the browse button
$browseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "All Files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox.Text = $openFileDialog.FileName
    }
})

# Event handler for the transfer button
$transferButton.Add_Click({
    $filePath = $textBox.Text
    if (Test-Path $filePath) {
        # Here you would add the code to transfer the file
        # For this example, we'll just simulate a transfer
        $statusLabel.Text = "Transferring file: $filePath"
        Start-Sleep -Seconds 2
        $statusLabel.Text = "File transferred successfully!"
    } else {
        $statusLabel.Text = "File not found."
    }
})

# Show the form
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
