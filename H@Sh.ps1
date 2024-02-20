# Define the expected hash value for the file
$expectedHash = "YOUR_EXPECTED_HASH_HERE"

# Function to calculate the hash of a file
function Get-FileHash($filePath) {
    $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
    $fileStream = [System.IO.File]::OpenRead($filePath)
    $hash = [BitConverter]::ToString($hashAlgorithm.ComputeHash($fileStream)) -replace '-'
    $fileStream.Close()
    return $hash
}

# Function to perform the hash check
function Verify-FileHash($filePath, $expectedHash) {
    $actualHash = Get-FileHash $filePath
    return $actualHash -eq $expectedHash
}

# GUI Code using Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "File Hash Checker"
$form.Size = New-Object Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"

$label = New-Object Windows.Forms.Label
$label.Text = "Select a file:"
$label.Location = New-Object Drawing.Point(10,20)
$label.AutoSize = $true

$textbox = New-Object Windows.Forms.TextBox
$textbox.Location = New-Object Drawing.Point(10,40)
$textbox.Size = New-Object Drawing.Size(200,20)

$button = New-Object Windows.Forms.Button
$button.Text = "Check Hash"
$button.Location = New-Object Drawing.Point(10,70)
$button.Add_Click({
    $filePath = $textbox.Text
    if (Test-Path $filePath) {
        $result = Verify-FileHash $filePath $expectedHash
        if ($result) {
            [Windows.Forms.MessageBox]::Show("Hash check passed!", "Success", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
        } else {
            [Windows.Forms.MessageBox]::Show("Hash check failed!", "Error", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [Windows.Forms.MessageBox]::Show("File not found!", "Error", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Add controls to the form
$form.Controls.Add($label)
$form.Controls.Add($textbox)
$form.Controls.Add($button)

# Display the form
$form.ShowDialog()
