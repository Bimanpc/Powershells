Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM Photo Cropper"
$form.Size = New-Object System.Drawing.Size(1000,700)
$form.StartPosition = "CenterScreen"

$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Location = New-Object System.Drawing.Point(10,10)
$pictureBox.Size = New-Object System.Drawing.Size(750,600)
$pictureBox.BorderStyle = "FixedSingle"
$pictureBox.SizeMode = "Zoom"
$form.Controls.Add($pictureBox)

$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = "Open Image"
$btnOpen.Location = New-Object System.Drawing.Point(800,20)
$form.Controls.Add($btnOpen)

$lblX = New-Object System.Windows.Forms.Label
$lblX.Text = "X"
$lblX.Location = New-Object System.Drawing.Point(800,80)
$form.Controls.Add($lblX)

$txtX = New-Object System.Windows.Forms.TextBox
$txtX.Location = New-Object System.Drawing.Point(850,80)
$txtX.Width = 100
$form.Controls.Add($txtX)

$lblY = New-Object System.Windows.Forms.Label
$lblY.Text = "Y"
$lblY.Location = New-Object System.Drawing.Point(800,120)
$form.Controls.Add($lblY)

$txtY = New-Object System.Windows.Forms.TextBox
$txtY.Location = New-Object System.Drawing.Point(850,120)
$txtY.Width = 100
$form.Controls.Add($txtY)

$lblW = New-Object System.Windows.Forms.Label
$lblW.Text = "Width"
$lblW.Location = New-Object System.Drawing.Point(800,160)
$form.Controls.Add($lblW)

$txtW = New-Object System.Windows.Forms.TextBox
$txtW.Location = New-Object System.Drawing.Point(850,160)
$txtW.Width = 100
$form.Controls.Add($txtW)

$lblH = New-Object System.Windows.Forms.Label
$lblH.Text = "Height"
$lblH.Location = New-Object System.Drawing.Point(800,200)
$form.Controls.Add($lblH)

$txtH = New-Object System.Windows.Forms.TextBox
$txtH.Location = New-Object System.Drawing.Point(850,200)
$txtH.Width = 100
$form.Controls.Add($txtH)

$btnCrop = New-Object System.Windows.Forms.Button
$btnCrop.Text = "Crop"
$btnCrop.Location = New-Object System.Drawing.Point(800,260)
$form.Controls.Add($btnCrop)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save"
$btnSave.Location = New-Object System.Drawing.Point(880,260)
$form.Controls.Add($btnSave)

$image = $null
$croppedImage = $null

$btnOpen.Add_Click({

    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Images|*.jpg;*.jpeg;*.png;*.bmp"

    if ($ofd.ShowDialog() -eq "OK") {
        $image = [System.Drawing.Bitmap\]::FromFile($ofd.FileName)
        $pictureBox.Image = $image
    }
})

$btnCrop.Add_Click({

    if ($image -eq $null) { return }

    try {

        $x = [int]$txtX.Text
        $y = [int]$txtY.Text
        $w = [int]$txtW.Text
        $h = [int]$txtH.Text

        $rect = New-Object System.Drawing.Rectangle($x,$y,$w,$h)

        $croppedImage = New-Object System.Drawing.Bitmap($w,$h)
        $graphics = [System.Drawing.Graphics\]::FromImage($croppedImage)

        $graphics.DrawImage(
            $image,
            0,0,
            $rect,
            [System.Drawing.GraphicsUnit\]::Pixel
        )

        $graphics.Dispose()

        $pictureBox.Image = $croppedImage

    }
    catch {
        [System.Windows.Forms.MessageBox\]::Show("Invalid crop values")
    }
})

$btnSave.Add_Click({

    if ($croppedImage -eq $null) { return }

    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "PNG|*.png|JPEG|*.jpg"

    if ($sfd.ShowDialog() -eq "OK") {

        $croppedImage.Save($sfd.FileName)
        [System.Windows.Forms.MessageBox\]::Show("Saved")
    }
})

[void]$form.ShowDialog()
