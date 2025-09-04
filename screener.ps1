# Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# -----------------------------
# Helpers: Capture, Region Select, Image Utils
# -----------------------------

function Get-AllScreensBounds {
    $bounds = [System.Drawing.Rectangle]::Empty
    foreach ($scr in [System.Windows.Forms.Screen]::AllScreens) {
        $bounds = [System.Drawing.Rectangle]::Union($bounds, $scr.Bounds)
    }
    return $bounds
}

function Capture-Fullscreen {
    $bounds = Get-AllScreensBounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $g.Dispose()
    return $bmp
}

function Show-RegionSelector {
    $overlay = New-Object System.Windows.Forms.Form
    $overlay.FormBorderStyle = 'None'
    $overlay.WindowState = 'Maximized'
    $overlay.TopMost = $true
    $overlay.Opacity = 0.15
    $overlay.BackColor = 'Black'
    $overlay.Cursor = [System.Windows.Forms.Cursors]::Cross

    $startPoint = [System.Drawing.Point]::Empty
    $currentRect = [System.Drawing.Rectangle]::Empty
    $selecting = $false
    $finalRect = $null

    $overlay.Add_Paint({
        param($s, $e)
        if ($selecting -and $currentRect.Width -gt 0 -and $currentRect.Height -gt 0) {
            $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Red), 2
            $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(50, [System.Drawing.Color]::Red))
            $e.Graphics.FillRectangle($brush, $currentRect)
            $e.Graphics.DrawRectangle($pen, $currentRect)
            $pen.Dispose(); $brush.Dispose()
        }
    })

    $overlay.Add_MouseDown({
        param($s, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $selecting = $true
            $startPoint = $e.Location
            $currentRect = [System.Drawing.Rectangle]::Empty
        }
    })

    $overlay.Add_MouseMove({
        param($s, $e)
        if ($selecting) {
            $x = [Math]::Min($startPoint.X, $e.X)
            $y = [Math]::Min($startPoint.Y, $e.Y)
            $w = [Math]::Abs($startPoint.X - $e.X)
            $h = [Math]::Abs($startPoint.Y - $e.Y)
            $currentRect = New-Object System.Drawing.Rectangle $x, $y, $w, $h
            $overlay.Invalidate()
        }
    })

    $overlay.Add_MouseUp({
        param($s, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $selecting) {
            $selecting = $false
            $finalRect = $currentRect
            $overlay.Close()
        } elseif ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            $finalRect = $null
            $overlay.Close()
        }
    })

    $overlay.ShowDialog() | Out-Null
    $overlay.Dispose()
    return $finalRect
}

function Capture-Region {
    $rect = Show-RegionSelector
    if (-not $rect -or $rect.Width -le 0 -or $rect.Height -le 0) { return $null }

    # Capture across virtual desktop coordinates
    $bmp = New-Object System.Drawing.Bitmap $rect.Width, $rect.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen([System.Drawing.Point]::new($rect.X, $rect.Y), [System.Drawing.Point]::Empty, $rect.Size)
    $g.Dispose()
    return $bmp
}

function Image-ToBase64Png {
    param([System.Drawing.Image]$Image)
    $ms = New-Object System.IO.MemoryStream
    $Image.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $ms.ToArray()
    $ms.Dispose()
    return [Convert]::ToBase64String($bytes)
}

function Save-ImageDialog {
    param([System.Drawing.Image]$Image)
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "PNG Image|*.png|JPEG Image|*.jpg;*.jpeg|BMP Image|*.bmp"
    $dlg.FileName = "capture.png"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $ext = [System.IO.Path]::GetExtension($dlg.FileName).ToLowerInvariant()
        switch ($ext) {
            ".png"  { $fmt = [System.Drawing.Imaging.ImageFormat]::Png }
            ".jpg"  { $fmt = [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".jpeg" { $fmt = [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".bmp"  { $fmt = [System.Drawing.Imaging.ImageFormat]::Bmp }
            default { $fmt = [System.Drawing.Imaging.ImageFormat]::Png }
        }
        $Image.Save($dlg.FileName, $fmt)
        return $dlg.FileName
    }
    return $null
}

function Load-ImageDialog {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Images|*.png;*.jpg;*.jpeg;*.bmp"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return [System.Drawing.Image]::FromFile($dlg.FileName)
    }
    return $null
}

# -----------------------------
# API call: send image to AI endpoint (Base64 JSON example)
# -----------------------------
function Send-ImageToAI {
    param(
        [string]$Endpoint,
        [string]$ApiKey,
        [string]$Model,
        [string]$Prompt,
        [System.Drawing.Image]$Image
    )

    if ([string]::IsNullOrWhiteSpace($Endpoint)) { throw "Endpoint is required." }
    if (-not $Image) { throw "No image to send." }

    $b64 = Image-ToBase64Png -Image $Image

    # Example JSON payload. Adjust for your API.
    # Common patterns:
    # - OpenAI/Azure OpenAI vision: { "model": "...", "input": [{"role":"user","content":[{"type":"text","text":"..."},{"type":"input_image","image_data":"base64"}]}]}
    # - Custom server: { "model": "...", "prompt": "...", "image_base64":"..." }
    $body = @{
        model = $Model
        prompt = $Prompt
        image_base64 = $b64
    } | ConvertTo-Json -Depth 6

    $headers = @{}
    if ($ApiKey) {
        # Adjust header name for your API if needed (e.g., "api-key", "Authorization" -> "Bearer <key>")
        $headers["Authorization"] = "Bearer $ApiKey"
    }

    $response = Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -ContentType "application/json" -Body $body
    return $response
}

# -----------------------------
# GUI
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM Screen Capture"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1100, 720)

# Controls
$btnFull = New-Object System.Windows.Forms.Button
$btnFull.Text = "Capture Fullscreen"
$btnFull.Size = New-Object System.Drawing.Size(160, 32)
$btnFull.Location = New-Object System.Drawing.Point(20, 20)

$btnRegion = New-Object System.Windows.Forms.Button
$btnRegion.Text = "Capture Region"
$btnRegion.Size = New-Object System.Drawing.Size(160, 32)
$btnRegion.Location = New-Object System.Drawing.Point(190, 20)

$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = "Open Image"
$btnOpen.Size = New-Object System.Drawing.Size(120, 32)
$btnOpen.Location = New-Object System.Drawing.Point(360, 20)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Image"
$btnSave.Size = New-Object System.Drawing.Size(120, 32)
$btnSave.Location = New-Object System.Drawing.Point(490, 20)

$pic = New-Object System.Windows.Forms.PictureBox
$pic.BorderStyle = 'FixedSingle'
$pic.SizeMode = 'Zoom'
$pic.Location = New-Object System.Drawing.Point(20, 70)
$pic.Size = New-Object System.Drawing.Size(700, 500)

$lblEndpoint = New-Object System.Windows.Forms.Label
$lblEndpoint.Text = "Endpoint:"
$lblEndpoint.Location = New-Object System.Drawing.Point(740, 20)
$lblEndpoint.AutoSize = $true

$txtEndpoint = New-Object System.Windows.Forms.TextBox
$txtEndpoint.Location = New-Object System.Drawing.Point(740, 40)
$txtEndpoint.Size = New-Object System.Drawing.Size(330, 24)
$txtEndpoint.Text = "http://localhost:11434/v1/vision"  # Example placeholder

$lblApiKey = New-Object System.Windows.Forms.Label
$lblApiKey.Text = "API Key (optional):"
$lblApiKey.Location = New-Object System.Drawing.Point(740, 70)
$lblApiKey.AutoSize = $true

$txtApiKey = New-Object System.Windows.Forms.TextBox
$txtApiKey.Location = New-Object System.Drawing.Point(740, 90)
$txtApiKey.Size = New-Object System.Drawing.Size(330, 24)
$txtApiKey.UseSystemPasswordChar = $true

$lblModel = New-Object System.Windows.Forms.Label
$lblModel.Text = "Model:"
$lblModel.Location = New-Object System.Drawing.Point(740, 120)
$lblModel.AutoSize = $true

$txtModel = New-Object System.Windows.Forms.TextBox
$txtModel.Location = New-Object System.Drawing.Point(740, 140)
$txtModel.Size = New-Object System.Drawing.Size(330, 24)
$txtModel.Text = "vision-model-name"

$lblPrompt = New-Object System.Windows.Forms.Label
$lblPrompt.Text = "Prompt:"
$lblPrompt.Location = New-Object System.Drawing.Point(740, 170)
$lblPrompt.AutoSize = $true

$txtPrompt = New-Object System.Windows.Forms.TextBox
$txtPrompt.Location = New-Object System.Drawing.Point(740, 190)
$txtPrompt.Size = New-Object System.Drawing.Size(330, 60)
$txtPrompt.Multiline = $true
$txtPrompt.Text = "Describe the screenshot and list any key information."

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Send to AI"
$btnSend.Size = New-Object System.Drawing.Size(120, 36)
$btnSend.Location = New-Object System.Drawing.Point(740, 260)

$btnCopyResp = New-Object System.Windows.Forms.Button
$btnCopyResp.Text = "Copy Response"
$btnCopyResp.Size = New-Object System.Drawing.Size(140, 32)
$btnCopyResp.Location = New-Object System.Drawing.Point(870, 260)

$txtResponse = New-Object System.Windows.Forms.TextBox
$txtResponse.Location = New-Object System.Drawing.Point(740, 300)
$txtResponse.Size = New-Object System.Drawing.Size(330, 270)
$txtResponse.Multiline = $true
$txtResponse.ScrollBars = 'Vertical'

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Size = New-Object System.Drawing.Size(120, 32)
$btnExit.Location = New-Object System.Drawing.Point(950, 580)

# State
$currentImage = $null

# Events
$btnFull.Add_Click({
    try {
        $img = Capture-Fullscreen
        if ($currentImage) { $currentImage.Dispose() }
        $currentImage = $img
        $pic.Image = $currentImage
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Fullscreen capture failed: $($_.Exception.Message)")
    }
})

$btnRegion.Add_Click({
    try {
        $img = Capture-Region
        if ($img -ne $null) {
            if ($currentImage) { $currentImage.Dispose() }
            $currentImage = $img
            $pic.Image = $currentImage
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Region capture failed: $($_.Exception.Message)")
    }
})

$btnOpen.Add_Click({
    try {
        $img = Load-ImageDialog
        if ($img -ne $null) {
            if ($currentImage) { $currentImage.Dispose() }
            $currentImage = $img
            $pic.Image = $currentImage
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Open image failed: $($_.Exception.Message)")
    }
})

$btnSave.Add_Click({
    try {
        if (-not $currentImage) {
            [System.Windows.Forms.MessageBox]::Show("No image to save.")
            return
        }
        $path = Save-ImageDialog -Image $currentImage
        if ($path) {
            [System.Windows.Forms.MessageBox]::Show("Saved: $path")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Save failed: $($_.Exception.Message)")
    }
})

$btnSend.Add_Click({
    try {
        if (-not $currentImage) {
            [System.Windows.Forms.MessageBox]::Show("Capture or load an image first.")
            return
        }
        $txtResponse.Text = "Sending..."
        $resp = Send-ImageToAI -Endpoint $txtEndpoint.Text -ApiKey $txtApiKey.Text -Model $txtModel.Text -Prompt $txtPrompt.Text -Image $currentImage

        # Try to render as readable text
        if ($resp -is [string]) {
            $txtResponse.Text = $resp
        } else {
            # Try common fields or fallback to JSON
            $possible = @(
                $resp.choices[0].message.content,
                $resp.output_text,
                $resp.result,
                $resp.message,
                $resp.response
            ) | Where-Object { $_ -ne $null } | Select-Object -First 1

            if ($possible) {
                $txtResponse.Text = [string]$possible
            } else {
                $txtResponse.Text = ($resp | ConvertTo-Json -Depth 8)
            }
        }
    } catch {
        $txtResponse.Text = "Request failed: $($_.Exception.Message)"
    }
})

$btnCopyResp.Add_Click({
    try {
        if ($txtResponse.Text) {
            [System.Windows.Forms.Clipboard]::SetText($txtResponse.Text)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Copy failed: $($_.Exception.Message)")
    }
})

$btnExit.Add_Click({ $form.Close() })

# Add controls
$form.Controls.AddRange(@(
    $btnFull, $btnRegion, $btnOpen, $btnSave,
    $pic,
    $lblEndpoint, $txtEndpoint,
    $lblApiKey, $txtApiKey,
    $lblModel, $txtModel,
    $lblPrompt, $txtPrompt,
    $btnSend, $btnCopyResp,
    $txtResponse,
    $btnExit
))

# Run
[void][System.Windows.Forms.Application]::EnableVisualStyles()
[void][System.Windows.Forms.Application]::Run($form)
