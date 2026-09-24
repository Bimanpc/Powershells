# NokiaPhotoEditor.ps1
# Local-only Nokia-style photo editor for Windows PowerShell 5.1
# Features: Open, Save As, Reset, Rotate, Flip, Grayscale,
# Sepia, Negative, Brightness, Contrast and Zoom.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application\]::EnableVisualStyles()

# -----------------------------
# Global image state
# -----------------------------
$script:OriginalImage = $null
$script:WorkingImage  = $null
$script:CurrentFile   = $null

# -----------------------------
# Colors
# -----------------------------
$NokiaBlue    = [System.Drawing.Color\]::FromArgb(18, 60, 120)
$NokiaDark    = [System.Drawing.Color\]::FromArgb(8, 31, 68)
$NokiaLight   = [System.Drawing.Color\]::FromArgb(40, 115, 190)
$PanelColor   = [System.Drawing.Color\]::FromArgb(22, 42, 67)
$ButtonColor  = [System.Drawing.Color\]::FromArgb(32, 86, 145)
$DisplayColor = [System.Drawing.Color\]::FromArgb(8, 15, 25)
$TextColor    = [System.Drawing.Color\]::White

function New-NokiaButton {
    param(
        [string]$Text,
        [int]$Width = 105,
        [int]$Height = 38
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle\]::Flat
    $button.FlatAppearance.BorderSize = 1
    $button.FlatAppearance.BorderColor = $NokiaLight
    $button.BackColor = $ButtonColor
    $button.ForeColor = $TextColor
    $button.Font = New-Object System.Drawing.Font(
        "Segoe UI",
        9,
        [System.Drawing.FontStyle\]::Bold
    )
    $button.Cursor = [System.Windows.Forms.Cursors\]::Hand

    $button.Add_MouseEnter({
        $this.BackColor = $NokiaLight
    })

    $button.Add_MouseLeave({
        $this.BackColor = $ButtonColor
    })

    return $button
}

function Test-ImageLoaded {
    if ($null -eq $script:WorkingImage) {
        [System.Windows.Forms.MessageBox\]::Show(
            "Please open an image first.",
            "Nokia Photo Editor",
            [System.Windows.Forms.MessageBoxButtons\]::OK,
            [System.Windows.Forms.MessageBoxIcon\]::Information
        ) | Out-Null

        return $false
    }

    return $true
}

function Set-WorkingImage {
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Bitmap]$Bitmap
    )

    if ($null -ne $script:WorkingImage) {
        $script:WorkingImage.Dispose()
    }

    $script:WorkingImage = $Bitmap
    $pictureBox.Image = $script:WorkingImage
    $statusLabel.Text = "Image: $($Bitmap.Width) x $($Bitmap.Height)"
    $pictureBox.Invalidate()
}

function Copy-Bitmap {
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Image]$Image
    )

    return New-Object System.Drawing.Bitmap($Image)
}

function Apply-ColorMatrix {
    param(
        [Parameter(Mandatory)]
        [System.Drawing.Imaging.ColorMatrix]$Matrix
    )

    if (-not (Test-ImageLoaded)) {
        return
    }

    $source = $script:WorkingImage
    $result = New-Object System.Drawing.Bitmap(
        $source.Width,
        $source.Height,
        [System.Drawing.Imaging.PixelFormat\]::Format32bppArgb
    )

    $graphics = [System.Drawing.Graphics\]::FromImage($result)
    $attributes = New-Object System.Drawing.Imaging.ImageAttributes

    try {
        $attributes.SetColorMatrix($Matrix)

        $destination = New-Object System.Drawing.Rectangle(
            0,
            0,
            $source.Width,
            $source.Height
        )

        $graphics.DrawImage(
            $source,
            $destination,
            0,
            0,
            $source.Width,
            $source.Height,
            [System.Drawing.GraphicsUnit\]::Pixel,
            $attributes
        )
    }
    finally {
        $attributes.Dispose()
        $graphics.Dispose()
    }

    Set-WorkingImage -Bitmap $result
}

function Apply-Brightness {
    param(
        [float]$Amount
    )

    $matrix = New-Object System.Drawing.Imaging.ColorMatrix
    $matrix.Matrix00 = 1
    $matrix.Matrix11 = 1
    $matrix.Matrix22 = 1
    $matrix.Matrix33 = 1
    $matrix.Matrix40 = $Amount
    $matrix.Matrix41 = $Amount
    $matrix.Matrix42 = $Amount
    $matrix.Matrix44 = 1

    Apply-ColorMatrix -Matrix $matrix
}

function Apply-Contrast {
    param(
        [float]$Amount
    )

    $translation = 0.5 * (1.0 - $Amount)

    $matrix = New-Object System.Drawing.Imaging.ColorMatrix
    $matrix.Matrix00 = $Amount
    $matrix.Matrix11 = $Amount
    $matrix.Matrix22 = $Amount
    $matrix.Matrix33 = 1
    $matrix.Matrix40 = $translation
    $matrix.Matrix41 = $translation
    $matrix.Matrix42 = $translation
    $matrix.Matrix44 = 1

    Apply-ColorMatrix -Matrix $matrix
}

# -----------------------------
# Main window
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Nokia Photo Editor"
$form.StartPosition = [System.Windows.Forms.FormStartPosition\]::CenterScreen
$form.Size = New-Object System.Drawing.Size(1180, 760)
$form.MinimumSize = New-Object System.Drawing.Size(900, 600)
$form.BackColor = $NokiaDark
$form.ForeColor = $TextColor
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.KeyPreview = $true

# -----------------------------
# Header
# -----------------------------
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = [System.Windows.Forms.DockStyle\]::Top
$headerPanel.Height = 72
$headerPanel.BackColor = $NokiaBlue

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "NOKIA PHOTO EDITOR"
$titleLabeltitleLabel.Location = New-Object System.Drawing.Point(22, 12)
$titleLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    20,
    [System.Drawing.FontStyle]::Bold
)
$titleLabel.ForeColor = $TextColor

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Local image editing | No cloud | No telemetry"
$subtitleLabel.AutoSize = $true
$subtitleLabel.Location = New-Object System.Drawing.Point(25, 48)
$subtitleLabel.ForeColor = [System.Drawing.Color]::LightCyan

$headerPanel.Controls.Add($titleLabel)
$headerPanel.Controls.Add($subtitleLabel)

# -----------------------------
# Toolbar
# -----------------------------
$toolbarPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$toolbarPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$toolbarPanel.Height = 58
$toolbarPanel.Padding = New-Object System.Windows.Forms.Padding(10, 9, 10, 5)
$toolbarPanel.BackColor = $PanelColor
$toolbarPanel.WrapContents = $false
$toolbarPanel.AutoScroll = $true

$openButton  = New-NokiaButton -Text "Open"
$saveButton  = New-NokiaButton -Text "Save As"
$resetButton = New-NokiaButton -Text "Reset"
$exitButton  = New-NokiaButton -Text "Exit"

$toolbarPanel.Controls.AddRange(@(
    $openButton,
    $saveButton,
    $resetButton,
    $exitButton
))

# -----------------------------
# Editor controls
# -----------------------------
$editorPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$editorPanel.Dock = [System.Windows.Forms.DockStyle]::Left
$editorPanel.Width = 145
$editorPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$editorPanel.BackColor = $PanelColor
$editorPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$editorPanel.WrapContents = $false
$editorPanel.AutoScroll = $true

$toolsLabel = New-Object System.Windows.Forms.Label
$toolsLabel.Text = "EDIT TOOLS"
$toolsLabel.Size = New-Object System.Drawing.Size(110, 30)
$toolsLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$toolsLabel.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10,
    [System.Drawing.FontStyle]::Bold
)
$toolsLabel.ForeColor = [System.Drawing.Color]::LightCyan

$rotateLeftButton  = New-NokiaButton -Text "Rotate Left"
$rotateRightButton = New-NokiaButton -Text "Rotate Right"
$flipHButton       = New-NokiaButton -Text "Flip Horizontal"
$flipVButton       = New-NokiaButton -Text "Flip Vertical"
$grayButton        = New-NokiaButton -Text "Grayscale"
$sepiaButton       = New-NokiaButton -Text "Sepia"
$negativeButton    = New-NokiaButton -Text "Negative"
$brightPlusButton  = New-NokiaButton -Text "Brightness +"
$brightMinusButton = New-NokiaButton -Text "Brightness -"
$contrastPlusButton  = New-NokiaButton -Text "Contrast +"
$contrastMinusButton = New-NokiaButton -Text "Contrast -"
$zoomButton        = New-NokiaButton -Text "Toggle Zoom"

$editorPanel.Controls.AddRange(@(
    $toolsLabel,
    $rotateLeftButton,
    $rotateRightButton,
    $flipHButton,
    $flipVButton,
    $grayButton,
    $sepiaButton,
    $negativeButton,
    $brightPlusButton,
    $brightMinusButton,
    $contrastPlusButton,
    $contrastMinusButton,
    $zoomButton
))

# -----------------------------
# Image display
# -----------------------------
$imagePanel = New-Object System.Windows.Forms.Panel
$imagePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$imagePanel.Padding = New-Object System.Windows.Forms.Padding(18)
$imagePanel.BackColor = $DisplayColor
$imagePanel.AutoScroll = $true

$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$pictureBox.BackColor = [System.Drawing.Color]::Black
$pictureBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom

$imagePanel.Controls.Add($pictureBox)

# -----------------------------
# Status bar
# -----------------------------
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = $NokiaBlue
$statusStrip.ForeColor = $TextColor

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready | Open an image to begin"
$statusLabel.Spring = $true
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

$statusStrip.Items.Add($statusLabel) | Out-Null

# Add in docking order
$form.Controls.Add($imagePanel)
$form.Controls.Add($editorPanel)
$form.Controls.Add($toolbarPanel)
$form.Controls.Add($headerPanel)
$form.Controls.Add($statusStrip)

# -----------------------------
# Open image
# -----------------------------
$openButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Open Image"
    $dialog.Filter = "Image files|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.tif;*.tiff|All files|*.*"

    try {
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $temporaryImage = [System.Drawing.Image]::FromFile($dialog.FileName)

            try {
                $loadedBitmap = New-Object System.Drawing.Bitmap($temporaryImage)
            }
            finally {
                $temporaryImage.Dispose()
            }

            if ($null -ne $script:OriginalImage) {
                $script:OriginalImage.Dispose()
            }

            if ($null -ne $script:WorkingImage) {
                $script:WorkingImage.Dispose()
            }

            $script:OriginalImage = Copy-Bitmap -Image $loadedBitmap
            $script:WorkingImage = $loadedBitmap
            $script:CurrentFile = $dialog.FileName

            $pictureBox.Image = $script:WorkingImage
            $statusLabel.Text = "Opened: $([System.IO.Path]::GetFileName($dialog.FileName)) | $($loadedBitmap.Width) x $($loadedBitmap.Height)"
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "The image could not be opened.`r`n`r`n$($_.Exception.Message)",
            "Open Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        $dialog.Dispose()
    }
})

# -----------------------------
# Save image
# -----------------------------
$saveButton.Add_Click({
    if (-not (Test-ImageLoaded)) {
        return
    }

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = "Save Edited Image"
    $dialog.Filter = "PNG image|*.png|JPEG image|*.jpg|Bitmap image|*.bmp"
    $dialog.DefaultExt = "png"
    $dialog.AddExtension = $true
    $dialog.FileName = "NokiaEditedImage.png"

    try {
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $extension = [System.IO.Path]::GetExtension($dialog.FileName).ToLowerInvariant()

            switch ($extension) {
                ".jpg" {
                    $format = [System.Drawing.Imaging.ImageFormat]::Jpeg
                }
                ".jpeg" {
                    $format = [System.Drawing.Imaging.ImageFormat]::Jpeg
                }
                ".bmp" {
                    $format = [System.Drawing.Imaging.ImageFormat]::Bmp
                }
                default {
                    $format = [System.Drawing.Imaging.ImageFormat]::Png
                }
            }

            $script:WorkingImage.Save($dialog.FileName, $format)
            $statusLabel.Text = "Saved: $([System.IO.Path]::GetFileName($dialog.FileName))"
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "The image could not be saved.`r`n`r`n$($_.Exception.Message)",
            "Save Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        $dialog.Dispose()
    }
})

# -----------------------------
# Reset
# -----------------------------
$resetButton.Add_Click({
    if ($null -eq $script:OriginalImage) {
        return
    }

    $resetBitmap = Copy-Bitmap -Image $script:OriginalImage
    Set-WorkingImage -Bitmap $resetBitmap
    $statusLabel.Text = "Image reset to original"
})

# -----------------------------
# Rotation and flipping
# -----------------------------
$rotateLeftButton.Add_Click({
    if (-not (Test-ImageLoaded)) {
        return
    }

    $script:WorkingImage.RotateFlip(
        [System.Drawing.RotateFlipType]::Rotate270FlipNone
    )

    $pictureBox.Image = $script:WorkingImage
    $pictureBox.Refresh()
    $statusLabel.Text = "Rotated left"
})

$rotateRightButton.Add_Click({
    if (-not (Test-ImageLoaded)) {
        return
    }

    $script:WorkingImage.RotateFlip(
        [System.Drawing.RotateFlipType]::Rotate90FlipNone
    )

    $pictureBox.Image = $script:WorkingImage
    $pictureBox.Refresh()
    $statusLabel.Text = "Rotated right"
})

$flipHButton.Add_Click({
    if (-not (Test-ImageLoaded)) {
        return
    }

    $script:WorkingImage.RotateFlip(
        [System.Drawing.RotateFlipType]::RotateNoneFlipX
    )

    $pictureBox.Refresh()
    $statusLabel.Text = "Flipped horizontally"
})

$flipVButton.Add_Click({
    if (-not (Test-ImageLoaded)) {
        return
    }

    $script:WorkingImage.RotateFlip(
        [System.Drawing.RotateFlipType]::RotateNoneFlipY
    )

    $pictureBox.Refresh()
    $statusLabel.Text = "Flipped vertically"
})

# -----------------------------
# Grayscale
# -----------------------------
$grayButton.Add_Click({
    $matrix = New-Object System.Drawing.Imaging.ColorMatrix

    $matrix.Matrix00 = 0.299
    $matrix.Matrix01 = 0.299
    $matrix.Matrix02 = 0.299

    $matrix.Matrix10 = 0.587
    $matrix.Matrix11 = 0.587
    $matrix.Matrix12 = 0.587

    $matrix.Matrix20 = 0.114
    $matrix.Matrix21 = 0.114
    $matrix.Matrix22 = 0.114

    $matrix.Matrix33 = 1
    $matrix.Matrix44 = 1

    Apply-ColorMatrix -Matrix $matrix
    $statusLabel.Text = "Grayscale filter applied"
})

# -----------------------------
# Sepia
# -----------------------------
$sepiaButton.Add_Click({
    $matrix = New-Object System.Drawing.Imaging.ColorMatrix

    $matrix.Matrix00 = 0.393
    $matrix.Matrix01 = 0.349
    $matrix.Matrix02 = 0.272

    $matrix.Matrix10 = 0.769
    $matrix.Matrix11 = 0.686
    $matrix.Matrix12 = 0.534

    $matrix.Matrix20 = 0.189
    $matrix.Matrix21 = 0.168
    $matrix.Matrix22 = 0.131

    $matrix.Matrix33 = 1
    $matrix.Matrix44 = 1

    Apply-ColorMatrix -Matrix $matrix
    $statusLabel.Text = "Sepia filter applied"
})

# -----------------------------
# Negative
# -----------------------------
$negativeButton.Add_Click({
    $matrix = New-Object System.Drawing.Imaging.ColorMatrix

    $matrix.Matrix00 = -1
    $matrix.Matrix11 = -1
    $matrix.Matrix22 = -1
    $matrix.Matrix33 = 1

    $matrix.Matrix40 = 1
    $matrix.Matrix41 = 1
    $matrix.Matrix42 = 1
    $matrix.Matrix44 = 1

    Apply-ColorMatrix -Matrix $matrix
    $statusLabel.Text = "Negative filter applied"
})

# -----------------------------
# Brightness and contrast
# -----------------------------
$brightPlusButton.Add_Click({
    Apply-Brightness -Amount 0.10
    $statusLabel.Text = "Brightness increased"
})

$brightMinusButton.Add_Click({
    Apply-Brightness -Amount -0.10
    $statusLabel.Text = "Brightness decreased"
})

$contrastPlusButton.Add_Click({
    Apply-Contrast -Amount 1.15
    $statusLabel.Text = "Contrast increased"
})

$contrastMinusButton.Add_Click({
    Apply-Contrast -Amount 0.85
    $statusLabel.Text = "Contrast decreased"
})

# -----------------------------
# Zoom mode
# -----------------------------
$zoomButton.Add_Click({
    if ($pictureBox.SizeMode -eq [System.Windows.Forms.PictureBoxSizeMode]::Zoom) {
        $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
        $statusLabel.Text = "Display mode: actual size"
    }
    else {
        $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $statusLabel.Text = "Display mode: fit to window"
    }
})

# -----------------------------
# Exit and cleanup
# -----------------------------
$exitButton.Add_Click({
    $form.Close()
})

$form.Add_KeyDown({
    param($sender, $eventArgs)

    if ($eventArgs.Control -and $eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::O) {
        $openButton.PerformClick()
    }

    if ($eventArgs.Control -and $eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::S) {
        $saveButton.PerformClick()
    }

    if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $form.Close()
    }
})

$form.Add_FormClosed({
    $pictureBox.Image = $null

    if ($null -ne $script:WorkingImage) {
        $script:WorkingImage.Dispose()
        $script:WorkingImage = $null
    }

    if ($null -ne $script:OriginalImage) {
        $script:OriginalImage.Dispose()
        $script:OriginalImage = $null
    }
})

[void]$form.ShowDialog()
