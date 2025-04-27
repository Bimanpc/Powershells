Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to encrypt a file
function Encrypt-File {
    param (
        [string]$filePath,
        [string]$password
    )

    $key = New-Object Byte[] 32
    $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
    $sha256 = New-Object System.Security.Cryptography.SHA256Managed
    $key = $sha256.ComputeHash($passwordBytes)[0..31]

    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = $key
    $aes.GenerateIV()

    $encryptor = $aes.CreateEncryptor()
    $encryptedBytes = [System.IO.File]::ReadAllBytes($filePath)
    $encryptedBytes = $aes.IV + [System.Security.Cryptography.CryptographicExtensions]::Encrypt($encryptor, $encryptedBytes)

    [System.IO.File]::WriteAllBytes("$filePath.locked", $encryptedBytes)
    Remove-Item -Path $filePath
}

# Function to decrypt a file
function Decrypt-File {
    param (
        [string]$filePath,
        [string]$password
    )

    $key = New-Object Byte[] 32
    $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
    $sha256 = New-Object System.Security.Cryptography.SHA256Managed
    $key = $sha256.ComputeHash($passwordBytes)[0..31]

    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = $key

    $encryptedBytes = [System.IO.File]::ReadAllBytes($filePath)
    $aes.IV = $encryptedBytes[0..15]
    $encryptedBytes = $encryptedBytes[16..($encryptedBytes.Length - 1)]

    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = [System.Security.Cryptography.CryptographicExtensions]::Decrypt($decryptor, $encryptedBytes)

    [System.IO.File]::WriteAllBytes([System.IO.Path]::ChangeExtension($filePath, ""), $decryptedBytes)
    Remove-Item -Path $filePath
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "File Locker"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label for the file path
$labelFilePath = New-Object System.Windows.Forms.Label
$labelFilePath.Text = "File Path:"
$labelFilePath.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($labelFilePath)

# Create a text box for the file path
$textBoxFilePath = New-Object System.Windows.Forms.TextBox
$textBoxFilePath.Location = New-Object System.Drawing.Point(10, 50)
$textBoxFilePath.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($textBoxFilePath)

# Create a button to browse for a file
$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse..."
$buttonBrowse.Location = New-Object System.Drawing.Point(290, 48)
$buttonBrowse.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxFilePath.Text = $openFileDialog.FileName
    }
})
$form.Controls.Add($buttonBrowse)

# Create a label for the password
$labelPassword = New-Object System.Windows.Forms.Label
$labelPassword.Text = "Password:"
$labelPassword.Location = New-Object System.Drawing.Point(10, 90)
$form.Controls.Add($labelPassword)

# Create a text box for the password
$textBoxPassword = New-Object System.Windows.Forms.TextBox
$textBoxPassword.Location = New-Object System.Drawing.Point(10, 120)
$textBoxPassword.Size = New-Object System.Drawing.Size(360, 20)
$textBoxPassword.PasswordChar = '*'
$form.Controls.Add($textBoxPassword)

# Create a button to lock the file
$buttonLock = New-Object System.Windows.Forms.Button
$buttonLock.Text = "Lock File"
$buttonLock.Location = New-Object System.Drawing.Point(10, 170)
$buttonLock.Add_Click({
    Encrypt-File -filePath $textBoxFilePath.Text -password $textBoxPassword.Text
    [System.Windows.Forms.MessageBox]::Show("File locked successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($buttonLock)

# Create a button to unlock the file
$buttonUnlock = New-Object System.Windows.Forms.Button
$buttonUnlock.Text = "Unlock File"
$buttonUnlock.Location = New-Object System.Drawing.Point(100, 170)
$buttonUnlock.Add_Click({
    Decrypt-File -filePath $textBoxFilePath.Text -password $textBoxPassword.Text
    [System.Windows.Forms.MessageBox]::Show("File unlocked successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($buttonUnlock)

# Show the form
$form.ShowDialog()
