Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Load ZXing library (installed via Install-Package ZXing.Net)
$zxingPath = "$HOME/.local/share/powershell/Modules/ZXing.Net/lib/net48/ZXing.Net.dll"
Add-Type -Path $zxingPath

# Window
$form = New-Object System.Windows.Forms.Form
$form.Text = "QR Code Maker - Ubuntu"
$form.Size = New-Object System.Drawing.Size(500,600)
$form.StartPosition = "CenterScreen"

# Input label
$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "Enter text or URL:"
$lbl.AutoSize = $true
$lbl.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($lbl)

# Input box
$txt = New-Object System.Windows.Forms.TextBox
$txt.Location = New-Object System.Drawing.Point(20,50)
$txt.Size = New-Object System.Drawing.Size(440,30)
$form.Controls.Add($txt)

# Picture box
$pic = New-Object System.Windows.Forms.PictureBox
$pic.Location = New-Object System.Drawing.Point(20,100)
$pic.Size = New-Object System.Drawing.Size(440,440)
$pic.BorderStyle = "FixedSingle"
$pic.SizeMode = "Zoom"
$form.Controls.Add($pic)

# Generate button
$btnGen = New-Object System.Windows.Forms.Button
$btnGen.Text = "Generate QR"
$btnGen.Location = New-Object System.Drawing.Point(20,550)
$btnGen.Size = New-Object System.Drawing.Size(150,30)
$form.Controls.Add($btnGen)

# Save button
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save PNG"
$btnSave.Location = New-Object System.Drawing.Point(200,550)
$btnSave.Size = New-Object System.Drawing.Size(150,30)
$form.Controls.Add($btnSave)

# QR generator
$writer = New-Object ZXing.BarcodeWriter
$writer.Format = [ZXing.BarcodeFormat]::QR_CODE

$btnGen.Add_Click({
    if ($txt.Text -eq "") { return }

    $bitmap = $writer.Write($txt.Text)
    $pic.Image = $bitmap
})

# Save PNG
$btnSave.Add_Click({
    if ($pic.Image -eq $null) { return }

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "PNG Image|*.png"
    $dialog.FileName = "qr.png"

    if ($dialog.ShowDialog() -eq "OK") {
        $pic.Image.Save($dialog.FileName, [System.Drawing.Imaging.ImageFormat]::Png)
    }
})

$form.ShowDialog()
