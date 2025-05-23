Add-Type -AssemblyName System.Windows.Forms
Add-Type -Path "path\to\itextsharp.dll" # Update this path to where iTextSharp.dll is located

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PDF Signer"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Select a PDF file to sign:"
$form.Controls.Add($label)

# Create a text box for the file path
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($textBox)

# Create a button to browse for the PDF file
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(10, 80)
$browseButton.Size = New-Object System.Drawing.Size(100, 30)
$browseButton.Text = "Browse"
$browseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "PDF Files (*.pdf)|*.pdf"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox.Text = $openFileDialog.FileName
    }
})
$form.Controls.Add($browseButton)

# Create a button to sign the PDF
$signButton = New-Object System.Windows.Forms.Button
$signButton.Location = New-Object System.Drawing.Point(10, 130)
$signButton.Size = New-Object System.Drawing.Size(100, 30)
$signButton.Text = "Sign PDF"
$signButton.Add_Click({
    $pdfPath = $textBox.Text
    if ([string]::IsNullOrEmpty($pdfPath)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a PDF file.")
        return
    }

    # Placeholder for signing logic using iTextSharp
    # You would need to implement the actual signing logic here
    [System.Windows.Forms.MessageBox]::Show("PDF signed successfully!")
})
$form.Controls.Add($signButton)

# Show the form
$form.ShowDialog()
