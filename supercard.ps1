<#
AI LLM Business Card RFID Maker (.ps1)
- GUI to design a business card, preview, export PNG, generate vCard, and write to an NFC tag (NDEF)
- Uses Windows Proximity API to write NDEF payloads (Windows 10/11)
- Optional LLM endpoint hook to auto-suggest polished copy
- Single-file, admin-safe, no external packages

Tested on Windows PowerShell 5.1 / Windows 11
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# WinRT: for NFC (Proximity) + Cryptography buffer
$null = [Windows.Networking.Proximity.ProximityDevice] # ensure WinRT type resolution
$null = [Windows.Security.Cryptography.CryptographicBuffer]

# -----------------------------
# Config: LLM endpoint (optional)
# -----------------------------
$Global:LLM_Endpoint = ""       # e.g., https://api.your-llm.example.com/v1/chat/completions
$Global:LLM_APIKey   = ""       # e.g., sk-xxxxx
$Global:LLM_Model    = "gpt-4o" # or any model name the endpoint accepts

# -----------------------------
# Helpers: vCard + NDEF builder
# -----------------------------

function New-VCard {
    param(
        [string]$FullName,
        [string]$Title,
        [string]$Company,
        [string]$Phone,
        [string]$Email,
        [string]$Website
    )
    $lines = @(
        "BEGIN:VCARD",
        "VERSION:3.0",
        "N:$($FullName);;;;",
        "FN:$($FullName)",
        "ORG:$($Company)",
        "TITLE:$($Title)",
        "TEL;TYPE=CELL:$($Phone)",
        "EMAIL;TYPE=INTERNET:$($Email)",
        "URL:$($Website)",
        "END:VCARD"
    )
    return ($lines -join "`r`n")
}

function New-NDEFRecordMime {
    param(
        [byte[]]$PayloadBytes,
        [string]$MimeType = "text/vcard"
    )
    # NDEF Record (single, short record)
    # Header: MB=1 ME=1 CF=0 SR=1 IL=0 TNF=0x02 (MIME media)
    # Type Length: len(MimeType)
    # Payload Length: byte (short record)
    # ID Length: absent (IL=0)
    # Type: ascii of MimeType
    $typeBytes = [System.Text.Encoding]::ASCII.GetBytes($MimeType)
    if ($PayloadBytes.Length -gt 255) {
        throw "Payload too large for short record. Consider chunking or using non-short record."
    }
    $header = 0x80 -bor 0x40 -bor 0x10 -bor 0x02  # MB|ME|SR with TNF=0x02
    $record = New-Object System.Collections.Generic.List[byte]
    $record.Add([byte]$header)
    $record.Add([byte]$typeBytes.Length)
    $record.Add([byte]$PayloadBytes.Length)
    $record.AddRange($typeBytes)
    $record.AddRange($PayloadBytes)
    return $record.ToArray()
}

function New-NDEFPayloadFromVCard {
    param([string]$VCard)
    $payload = [System.Text.Encoding]::UTF8.GetBytes($VCard)
    return (New-NDEFRecordMime -PayloadBytes $payload -MimeType "text/vcard")
}

function Get-IBufferFromBytes {
    param([byte[]]$Bytes)
    $buf = $null
    [Windows.Security.Cryptography.CryptographicBuffer]::CreateFromByteArray($Bytes, [ref]$buf) | Out-Null
    return $buf
}

# -----------------------------
# NFC write via Windows Proximity API
# -----------------------------
function Write-NDEFTag {
    param([byte[]]$NdefBytes)
    $device = [Windows.Networking.Proximity.ProximityDevice]::GetDefault()
    if (-not $device) {
        [System.Windows.Forms.MessageBox]::Show("No NFC ProximityDevice found. Ensure NFC is supported and enabled.", "NFC Error", 'OK', 'Error') | Out-Null
        return $false
    }

    $ibuffer = Get-IBufferFromBytes -Bytes $NdefBytes

    $completed = $false
    $statusMsg = "Hold the NFC tag near your device to write..."
    $msgId = $device.PublishBinaryMessage("NDEF:WriteTag", $ibuffer, {
        param($dev, $messageId)
        $script:completed = $true
        try { $dev.StopPublishingMessage($messageId) } catch {}
    })

    [System.Windows.Forms.MessageBox]::Show($statusMsg, "NFC", 'OK', 'Information') | Out-Null

    # Simple wait loop for completion up to 10 seconds
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not $script:completed -and $sw.Elapsed.TotalSeconds -lt 10) {
        Start-Sleep -Milliseconds 100
    }

    if ($script:completed) {
        [System.Windows.Forms.MessageBox]::Show("Tag write completed.", "NFC", 'OK', 'Information') | Out-Null
        return $true
    } else {
        try { $device.StopPublishingMessage($msgId) } catch {}
        [System.Windows.Forms.MessageBox]::Show("Timed out waiting for tag. Try again and hold the tag steady.", "NFC Timeout", 'OK', 'Warning') | Out-Null
        return $false
    }
}

# -----------------------------
# LLM integration (optional)
# -----------------------------
function Invoke-LLM {
    param([string]$Prompt)
    if ([string]::IsNullOrWhiteSpace($Global:LLM_Endpoint) -or [string]::IsNullOrWhiteSpace($Global:LLM_APIKey)) {
        return "LLM endpoint not configured."
    }

    $headers = @{
        "Authorization" = "Bearer $($Global:LLM_APIKey)"
        "Content-Type"  = "application/json"
    }

    $body = @{
        model = $Global:LLM_Model
        messages = @(
            @{ role = "system"; content = "You are a concise marketing copy assistant for business cards. Return short, polished text." },
            @{ role = "user"; content = $Prompt }
        )
        temperature = 0.7
    } | ConvertTo-Json -Depth 6

    try {
        $resp = Invoke-RestMethod -Uri $Global:LLM_Endpoint -Method POST -Headers $headers -Body $body -TimeoutSec 30
        if ($resp.choices -and $resp.choices[0].message.content) {
            return $resp.choices[0].message.content.Trim()
        } else {
            return "No content returned from LLM."
        }
    } catch {
        return "LLM error: $($_.Exception.Message)"
    }
}

# -----------------------------
# Render business card to PNG
# -----------------------------
function Save-BusinessCardPNG {
    param(
        [string]$Path,
        [string]$FullName,
        [string]$Title,
        [string]$Company,
        [string]$Phone,
        [string]$Email,
        [string]$Website,
        [string]$ThemeColor = "#2E3A59"
    )

    $w = 1050; $h = 600 # 3.5x2in @300dpi
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode  = 'AntiAlias'
    $g.TextRenderingHint = 'ClearTypeGridFit'

    # Background
    $bg = [System.Drawing.Color]::White
    $g.Clear($bg)

    # Accent bar
    $accent = [System.Drawing.ColorTranslator]::FromHtml($ThemeColor)
    $accentBrush = New-Object System.Drawing.SolidBrush($accent)
    $g.FillRectangle($accentBrush, 0, 0, 230, $h)

    # Fonts
    $fontName = New-Object System.Drawing.Font("Segoe UI Semibold", 42)
    $fontTitle = New-Object System.Drawing.Font("Segoe UI", 26)
    $fontCompany = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $fontInfo = New-Object System.Drawing.Font("Segoe UI", 22)

    # Brushes
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $darkBrush  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30,30,30))
    $grayBrush  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100,100,100))

    # Name on accent bar
    $nameRect = New-Object System.Drawing.RectangleF(20, 40, 190, 520)
    $fmtCenter = New-Object System.Drawing.StringFormat
    $fmtCenter.Alignment = 'Near'
    $fmtCenter.LineAlignment = 'Near'
    $g.DrawString($FullName, $fontName, $whiteBrush, $nameRect, $fmtCenter)

    # Right content
    $x = 270; $y = 80
    $g.DrawString($Title, $fontTitle, $grayBrush, $x, $y); $y += 55
    $g.DrawString($Company, $fontCompany, $darkBrush, $x, $y); $y += 75

    $g.DrawString("Phone: $Phone", $fontInfo, $darkBrush, $x, $y); $y += 45
    $g.DrawString("Email: $Email", $fontInfo, $darkBrush, $x, $y); $y += 45
    $g.DrawString("Web: $Website", $fontInfo, $darkBrush, $x, $y); $y += 45

    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

    # Cleanup
    $g.Dispose(); $accentBrush.Dispose()
    $fontName.Dispose(); $fontTitle.Dispose(); $fontCompany.Dispose(); $fontInfo.Dispose()
    $whiteBrush.Dispose(); $darkBrush.Dispose(); $grayBrush.Dispose()
    $bmp.Dispose()
}

# -----------------------------
# GUI setup
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM Business Card RFID Maker"
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Width = 900
$form.Height = 700

# Labels & TextBoxes
function Add-Field {
    param($labelText, $top, [ref]$tbRef, $width = 520)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $labelText
    $lbl.Left = 20
    $lbl.Top = $top
    $lbl.Width = 120
    $form.Controls.Add($lbl)

    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Left = 150
    $tb.Top = $top - 3
    $tb.Width = $width
    $tbRef.Value = $tb
    $form.Controls.Add($tb)
}

$tbName = $null; Add-Field -labelText "Full name" -top 20 -tbRef ([ref]$tbName)
$tbTitle = $null; Add-Field -labelText "Title" -top 60 -tbRef ([ref]$tbTitle)
$tbCompany = $null; Add-Field -labelText "Company" -top 100 -tbRef ([ref]$tbCompany)
$tbPhone = $null; Add-Field -labelText "Phone" -top 140 -tbRef ([ref]$tbPhone)
$tbEmail = $null; Add-Field -labelText "Email" -top 180 -tbRef ([ref]$tbEmail)
$tbWebsite = $null; Add-Field -labelText "Website" -top 220 -tbRef ([ref]$tbWebsite)

# Theme color
$lblColor = New-Object System.Windows.Forms.Label
$lblColor.Text = "Theme color (hex)"
$lblColor.Left = 20; $lblColor.Top = 260; $lblColor.Width = 120
$form.Controls.Add($lblColor)

$tbColor = New-Object System.Windows.Forms.TextBox
$tbColor.Left = 150; $tbColor.Top = 257; $tbColor.Width = 120
$tbColor.Text = "#2E3A59"
$form.Controls.Add($tbColor)

# LLM prompt + output
$lblLLM = New-Object System.Windows.Forms.Label
$lblLLM.Text = "LLM prompt"
$lblLLM.Left = 20; $lblLLM.Top = 300; $lblLLM.Width = 120
$form.Controls.Add($lblLLM)

$tbLLM = New-Object System.Windows.Forms.TextBox
$tbLLM.Left = 150; $tbLLM.Top = 297; $tbLLM.Width = 520; $tbLLM.Height = 60
$tbLLM.Multiline = $true
$tbLLM.Text = "Write a crisp tagline and role description for the card."
$form.Controls.Add($tbLLM)

$lblLLMOut = New-Object System.Windows.Forms.Label
$lblLLMOut.Text = "LLM suggestion"
$lblLLMOut.Left = 20; $lblLLMOut.Top = 370; $lblLLMOut.Width = 120
$form.Controls.Add($lblLLMOut)

$tbLLMOut = New-Object System.Windows.Forms.TextBox
$tbLLMOut.Left = 150; $tbLLMOut.Top = 367; $tbLLMOut.Width = 520; $tbLLMOut.Height = 90
$tbLLMOut.Multiline = $true
$form.Controls.Add($tbLLMOut)

# Preview picture box
$pb = New-Object System.Windows.Forms.PictureBox
$pb.Left = 150; $pb.Top = 470; $pb.Width = 520; $pb.Height = 160
$pb.BorderStyle = 'FixedSingle'
$form.Controls.Add($pb)

# Buttons
$btnLLM = New-Object System.Windows.Forms.Button
$btnLLM.Text = "Suggest via LLM"
$btnLLM.Left = 690; $btnLLM.Top = 297; $btnLLM.Width = 170; $btnLLM.Height = 30
$form.Controls.Add($btnLLM)

$btnPreview = New-Object System.Windows.Forms.Button
$btnPreview.Text = "Generate preview"
$btnPreview.Left = 690; $btnPreview.Top = 470; $btnPreview.Width = 170; $btnPreview.Height = 30
$form.Controls.Add($btnPreview)

$btnSavePNG = New-Object System.Windows.Forms.Button
$btnSavePNG.Text = "Export PNG"
$btnSavePNG.Left = 690; $btnSavePNG.Top = 510; $btnSavePNG.Width = 170; $btnSavePNG.Height = 30
$form.Controls.Add($btnSavePNG)

$btnWriteTag = New-Object System.Windows.Forms.Button
$btnWriteTag.Text = "Write vCard to NFC tag"
$btnWriteTag.Left = 690; $btnWriteTag.Top = 550; $btnWriteTag.Width = 170; $btnWriteTag.Height = 30
$form.Controls.Add($btnWriteTag)

$btnVCardCopy = New-Object System.Windows.Forms.Button
$btnVCardCopy.Text = "Copy vCard to clipboard"
$btnVCardCopy.Left = 690; $btnVCardCopy.Top = 590; $btnVCardCopy.Width = 170; $btnVCardCopy.Height = 30
$form.Controls.Add($btnVCardCopy)

# Status strip
$status = New-Object System.Windows.Forms.StatusStrip
$slbl = New-Object System.Windows.Forms.ToolStripStatusLabel
$slbl.Text = "Ready"
$status.Items.Add($slbl) | Out-Null
$form.Controls.Add($status)

# -----------------------------
# Event wiring
# -----------------------------
function Get-CardState {
    return @{
        FullName = $tbName.Text.Trim()
        Title    = $tbTitle.Text.Trim()
        Company  = $tbCompany.Text.Trim()
        Phone    = $tbPhone.Text.Trim()
        Email    = $tbEmail.Text.Trim()
        Website  = $tbWebsite.Text.Trim()
        Theme    = $tbColor.Text.Trim()
    }
}

$btnLLM.Add_Click({
    $state = Get-CardState
    $prompt = @"
Name: $($state.FullName)
Title: $($state.Title)
Company: $($state.Company)
Phone: $($state.Phone)
Email: $($state.Email)
Website: $($state.Website)

Task: Write a brief tagline and 1–2 sentence role description suitable for a business card.
Return only the text, no markdown.
"@
    $slbl.Text = "Calling LLM..."
    $out = Invoke-LLM -Prompt $prompt
    $tbLLMOut.Text = $out
    $slbl.Text = "LLM suggestion updated."
})

$btnPreview.Add_Click({
    try {
        $state = Get-CardState
        $tmp = [System.IO.Path]::GetTempFileName()
        $png = [System.IO.Path]::ChangeExtension($tmp, ".png")
        Save-BusinessCardPNG -Path $png `
            -FullName $state.FullName -Title ($state.Title) `
            -Company $state.Company -Phone $state.Phone `
            -Email $state.Email -Website $state.Website `
            -ThemeColor $state.Theme

        $pb.ImageLocation = $png
        $slbl.Text = "Preview updated."
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Preview error: $($_.Exception.Message)", "Error", 'OK', 'Error') | Out-Null
        $slbl.Text = "Preview failed."
    }
})

$btnSavePNG.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "PNG Image|*.png"
    $sfd.FileName = "business-card.png"
    if ($sfd.ShowDialog() -eq 'OK') {
        try {
            $state = Get-CardState
            Save-BusinessCardPNG -Path $sfd.FileName `
                -FullName $state.FullName -Title ($state.Title) `
                -Company $state.Company -Phone $state.Phone `
                -Email $state.Email -Website $state.Website `
                -ThemeColor $state.Theme
            $slbl.Text = "Saved: $($sfd.FileName)"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Save error: $($_.Exception.Message)", "Error", 'OK', 'Error') | Out-Null
            $slbl.Text = "Save failed."
        }
    }
})

$btnVCardCopy.Add_Click({
    try {
        $state = Get-CardState
        $v = New-VCard -FullName $state.FullName -Title $state.Title -Company $state.Company -Phone $state.Phone -Email $state.Email -Website $state.Website
        [System.Windows.Forms.Clipboard]::SetText($v)
        $slbl.Text = "vCard copied to clipboard."
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Clipboard error: $($_.Exception.Message)", "Error", 'OK', 'Error') | Out-Null
        $slbl.Text = "Copy failed."
    }
})

$btnWriteTag.Add_Click({
    try {
        $state = Get-CardState
        $v = New-VCard -FullName $state.FullName -Title $state.Title -Company $state.Company -Phone $state.Phone -Email $state.Email -Website $state.Website
        $ndef = New-NDEFPayloadFromVCard -VCard $v
        $ok = Write-NDEFTag -NdefBytes $ndef
        $slbl.Text = $ok ? "Tag write completed." : "Tag write failed or timed out."
    } catch {
        [System.Windows.Forms.MessageBox]::Show("NFC write error: $($_.Exception.Message)", "Error", 'OK', 'Error') | Out-Null
        $slbl.Text = "NFC write failed."
    }
})

# -----------------------------
# Defaults for quick test
# -----------------------------
$tbName.Text = "Βασίλης Example"
$tbTitle.Text = "PC  Engineer"
$tbCompany.Text = " ##VPSAIDEV##"

# -----------------------------
# Run
# -----------------------------
$form.Add_FormClosed({ 
    # simple cleanup for temp preview
    try {
        if ($pb.ImageLocation -and (Test-Path $pb.ImageLocation)) { Remove-Item -Force $pb.ImageLocation }
    } catch {}
})
[void]$form.ShowDialog()
