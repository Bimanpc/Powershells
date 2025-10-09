#requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# ==============================
# Config: LLM endpoint (placeholder)
# ==============================
$Global:LLM_Endpoint = "https://your-llm-endpoint.example/v1/generate"
$Global:LLM_ApiKey   = "YOUR_API_KEY"
$Global:LLM_Model    = "your-model-name"
$Global:LLM_TimeoutS = 30

# ==============================
# State
# ==============================
$Global:Project = [ordered]@{
    ImagePath   = $null
    SiteNotes   = ""
    Cameras     = @()   # Each: [ordered]@{Id;X;Y;HeightM;LensMM;AzimuthDeg;TiltDeg;HFOVDeg;IR;Resolution;Label}
    ShowMarkers = $true
    ShowFOV     = $true
}
$Global:NextId = 1
$Global:Image  = $null
$Global:Scale  = 1.0
$Global:Pan    = New-Object System.Drawing.Point(0,0)
$Global:HoverCamId = $null

# ==============================
# Helpers
# ==============================
function New-Camera {
    param(
        [int]$X,[int]$Y,
        [double]$HeightM = 3.0,
        [double]$LensMM  = 3.6,
        [double]$AzimuthDeg = 0.0,
        [double]$TiltDeg    = -10.0,
        [double]$HFOVDeg    = 80.0,
        [bool]$IR = $true,
        [string]$Resolution = "4MP",
        [string]$Label = ""
    )
    [ordered]@{
        Id          = $Global:NextId++
        X           = [int]$X
        Y           = [int]$Y
        HeightM     = [double]$HeightM
        LensMM      = [double]$LensMM
        AzimuthDeg  = [double]$AzimuthDeg
        TiltDeg     = [double]$TiltDeg
        HFOVDeg     = [double]$HFOVDeg
        IR          = [bool]$IR
        Resolution  = [string]$Resolution
        Label       = [string]$Label
    }
}

function Get-CameraById { param([int]$Id) $Global:Project.Cameras | Where-Object { $_.Id -eq $Id } }

function To-JSON { param($obj) return (ConvertTo-Json $obj -Depth 6) }

function From-JSON { param([string]$json) return (ConvertFrom-Json $json) }

function Save-Project {
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "CCTV Designer Project (*.json)|*.json"
    $sfd.Title  = "Save Project"
    if ($sfd.ShowDialog() -eq 'OK') {
        [IO.File]::WriteAllText($sfd.FileName, (To-JSON $Global:Project))
    }
}

function Load-Project {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "CCTV Designer Project (*.json)|*.json"
    $ofd.Title  = "Open Project"
    if ($ofd.ShowDialog() -eq 'OK') {
        $p = From-JSON ([IO.File]::ReadAllText($ofd.FileName))
        # Convert PSCustomObject to ordered hashtable
        $Global:Project = [ordered]@{
            ImagePath   = [string]$p.ImagePath
            SiteNotes   = [string]$p.SiteNotes
            Cameras     = @()
            ShowMarkers = [bool]$p.ShowMarkers
            ShowFOV     = [bool]$p.ShowFOV
        }
        $Global:NextId = 1
        foreach ($c in $p.Cameras) {
            $cam = New-Camera -X $c.X -Y $c.Y -HeightM $c.HeightM -LensMM $c.LensMM -AzimuthDeg $c.AzimuthDeg -TiltDeg $c.TiltDeg -HFOVDeg $c.HFOVDeg -IR $c.IR -Resolution $c.Resolution -Label $c.Label
            $cam.Id = $c.Id
            $Global:Project.Cameras += $cam
            if ($c.Id -ge $Global:NextId) { $Global:NextId = $c.Id + 1 }
        }
        Load-Image $Global:Project.ImagePath
        $tbSiteNotes.Text = $Global:Project.SiteNotes
        $pb.Invalidate()
    }
}

function Load-Image {
    param([string]$path)
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path $path)) { return }
    if ($Global:Image) { $Global:Image.Dispose() }
    $Global:Image = [System.Drawing.Image]::FromFile($path)
    $Global:Project.ImagePath = $path
    Fit-To-Window
}

function Fit-To-Window {
    if (-not $Global:Image) { return }
    $imgW = $Global:Image.Width
    $imgH = $Global:Image.Height
    $viewW = $pb.ClientSize.Width
    $viewH = $pb.ClientSize.Height
    if ($imgW -le 0 -or $imgH -le 0 -or $viewW -le 0 -or $viewH -le 0) { return }
    $scaleX = $viewW / $imgW
    $scaleY = $viewH / $imgH
    $Global:Scale = [Math]::Min($scaleX, $scaleY)
    $Global:Pan = New-Object System.Drawing.Point(
        [int](([double]$viewW - $imgW * $Global:Scale)/2),
        [int](([double]$viewH - $imgH * $Global:Scale)/2)
    )
    $pb.Invalidate()
}

function ViewToImagePoint {
    param([System.Drawing.Point]$pt)
    $xImg = [int](([double]($pt.X - $Global:Pan.X)) / $Global:Scale)
    $yImg = [int](([double]($pt.Y - $Global:Pan.Y)) / $Global:Scale)
    [System.Drawing.Point]::new($xImg,$yImg)
}

function ImageToViewPoint {
    param([System.Drawing.Point]$pt)
    $xView = [int]($Global:Pan.X + $pt.X * $Global:Scale)
    $yView = [int]($Global:Pan.Y + $pt.Y * $Global:Scale)
    [System.Drawing.Point]::new($xView,$yView)
}

function Draw-CameraMarker {
    param($g,$cam)
    $p = ImageToViewPoint ([System.Drawing.Point]::new($cam.X,$cam.Y))
    $size = [int](10 * $Global:Scale)
    if ($size -lt 6) { $size = 6 }
    $rect = New-Object System.Drawing.Rectangle($p.X - $size,$p.Y - $size,$size*2,$size*2)
    $color = [System.Drawing.Color]::FromArgb(220,0,122,204)
    $pen   = New-Object System.Drawing.Pen($color,2)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80,0,122,204))
    $g.FillEllipse($brush,$rect)
    $g.DrawEllipse($pen,$rect)
    $font = New-Object System.Drawing.Font("Segoe UI",8)
    $label = if ([string]::IsNullOrWhiteSpace($cam.Label)) { "Cam $($cam.Id)" } else { $cam.Label }
    $g.DrawString($label,$font,[System.Drawing.Brushes]::White,[System.Drawing.PointF]::new($p.X+$size+4,$p.Y-$size-2))
    $pen.Dispose(); $brush.Dispose(); $font.Dispose()
}

function Draw-FOV {
    param($g,$cam)
    # Simple wedge based on azimuth and HFOV
    $center = ImageToViewPoint ([System.Drawing.Point]::new($cam.X,$cam.Y))
    $radius = [int](120 * $Global:Scale)
    if ($radius -lt 60) { $radius = 60 }
    $az = $cam.AzimuthDeg * [Math]::PI / 180.0
    $half = ($cam.HFOVDeg/2.0) * [Math]::PI / 180.0
    $leftAng  = $az - $half
    $rightAng = $az + $half
    $pLeft  = [System.Drawing.Point]::new($center.X + [int]([Math]::Cos($leftAng) * $radius),  $center.Y + [int]([Math]::Sin($leftAng) * $radius))
    $pRight = [System.Drawing.Point]::new($center.X + [int]([Math]::Cos($rightAng) * $radius), $center.Y + [int]([Math]::Sin($rightAng) * $radius))
    $poly = @($center,$pLeft,$pRight)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50,255,193,7))
    $pen   = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180,255,193,7),2)
    $g.FillPolygon($brush,$poly)
    $g.DrawPolygon($pen,$poly)
    $brush.Dispose(); $pen.Dispose()
}

function HitTest-CameraId {
    param([System.Drawing.Point]$viewPt)
    foreach ($cam in $Global:Project.Cameras) {
        $p = ImageToViewPoint ([System.Drawing.Point]::new($cam.X,$cam.Y))
        $size = [int](10 * $Global:Scale)
        if ($size -lt 6) { $size = 6 }
        $rect = New-Object System.Drawing.Rectangle($p.X - $size,$p.Y - $size,$size*2,$size*2)
        if ($rect.Contains($viewPt)) { return $cam.Id }
    }
    return $null
}

function Edit-CameraDialog {
    param($cam)
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Edit Camera $($cam.Id)"
    $dlg.Size = New-Object System.Drawing.Size(360,420)
    $dlg.StartPosition = 'CenterParent'
    $dlg.FormBorderStyle = 'FixedDialog'
    $dlg.MaximizeBox = $false; $dlg.MinimizeBox = $false

    function AddRow($parent,$labelText,$y,$default) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $labelText
        $lbl.Location = New-Object System.Drawing.Point(12,$y)
        $lbl.Size = New-Object System.Drawing.Size(120,24)
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Location = New-Object System.Drawing.Point(140,$y)
        $tb.Size = New-Object System.Drawing.Size(180,24)
        $tb.Text = [string]$default
        $parent.Controls.Add($lbl); $parent.Controls.Add($tb)
        return $tb
    }
    $y = 12
    $tbLabel      = AddRow $dlg "Label"       $y            $cam.Label;      $y += 30
    $tbHeight     = AddRow $dlg "Height (m)"  $y            $cam.HeightM;    $y += 30
    $tbLens       = AddRow $dlg "Lens (mm)"   $y            $cam.LensMM;     $y += 30
    $tbAzimuth    = AddRow $dlg "Azimuth (°)" $y            $cam.AzimuthDeg; $y += 30
    $tbTilt       = AddRow $dlg "Tilt (°)"    $y            $cam.TiltDeg;    $y += 30
    $tbHFOV       = AddRow $dlg "HFOV (°)"    $y            $cam.HFOVDeg;    $y += 30
    $tbRes        = AddRow $dlg "Resolution"  $y            $cam.Resolution; $y += 30

    $chkIR = New-Object System.Windows.Forms.CheckBox
    $chkIR.Text = "IR enabled"
    $chkIR.Location = New-Object System.Drawing.Point(140,$y); $y += 34
    $chkIR.Checked = [bool]$cam.IR
    $dlg.Controls.Add($chkIR)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(140,$y)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(230,$y)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dlg.Controls.Add($btnCancel)

    if ($dlg.ShowDialog() -eq 'OK') {
        $cam.Label      = $tbLabel.Text
        $cam.HeightM    = [double]$tbHeight.Text
        $cam.LensMM     = [double]$tbLens.Text
        $cam.AzimuthDeg = [double]$tbAzimuth.Text
        $cam.TiltDeg    = [double]$tbTilt.Text
        $cam.HFOVDeg    = [double]$tbHFOV.Text
        $cam.Resolution = $tbRes.Text
        $cam.IR         = $chkIR.Checked
        return $true
    }
    return $false
}

function Remove-Camera {
    param([int]$Id)
    $Global:Project.Cameras = @($Global:Project.Cameras | Where-Object { $_.Id -ne $Id })
}

function Call-LLM {
    param([string]$prompt,[hashtable]$payload)
    # Minimal JSON POST. Adjust to your endpoint spec.
    $body = @{
        model   = $Global:LLM_Model
        input   = $prompt
        data    = $payload
        stream  = $false
    } | ConvertTo-Json -Depth 6

    $headers = @{
        "Authorization" = "Bearer $($Global:LLM_ApiKey)"
        "Content-Type"  = "application/json"
    }
    try {
        $req = [System.Net.HttpWebRequest]::Create($Global:LLM_Endpoint)
        $req.Method = "POST"
        foreach ($k in $headers.Keys) { $req.Headers.Add($k,$headers[$k]) }
        $req.Timeout = $Global:LLM_TimeoutS * 1000
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $req.ContentLength = $bytes.Length
        $stream = $req.GetRequestStream()
        $stream.Write($bytes,0,$bytes.Length)
        $stream.Close()
        $resp = $req.GetResponse()
        $rs   = $resp.GetResponseStream()
        $sr   = New-Object System.IO.StreamReader($rs)
        $text = $sr.ReadToEnd()
        $sr.Close(); $rs.Close(); $resp.Close()
        return $text
    } catch {
        return "LLM error: $($_.Exception.Message)"
    }
}

function Build-LLMPrompt {
    # Summarize context for the LLM
    $notes = $Global:Project.SiteNotes
    $cams  = $Global:Project.Cameras | ForEach-Object {
        "- Cam $($_.Id) [$($_.Label)]: pos=($($_.X),$($_.Y)), height=$($_.HeightM)m, lens=$($_.LensMM)mm, azimuth=$($_.AzimuthDeg)°, tilt=$($_.TiltDeg)°, HFOV=$($_.HFOVDeg)°, IR=$($_.IR), res=$($_.Resolution)"
    } -join "`n"
    @"
You are an expert CCTV designer for exterior surveillance.
Given a site image (not provided) and the camera layout metadata, produce:

1) A coverage assessment: blind spots, overlapping FOVs, suggested azimuth/tilt tweaks.
2) Placement recommendations for entrances, perimeter, parking, and high-value areas.
3) Hardware suggestions: lens, resolution, IR, WDR, weather rating, mount types.
4) A concise installation plan with cable runs and NVR channel allocation.

Site notes:
$notes

Current cameras:
$cams

Return a structured summary and a bullet-point action plan.
"@
}

function Build-LLMDataPayload {
    @{
        imagePath = $Global:Project.ImagePath
        cameras   = $Global:Project.Cameras
        siteNotes = $Global:Project.SiteNotes
        createdAt = (Get-Date).ToString("s")
    }
}

# ==============================
# UI
# ==============================
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM CCTV Exterior Designer"
$form.Size = New-Object System.Drawing.Size(1200,800)
$form.StartPosition = 'CenterScreen'

# Menu
$menu = New-Object System.Windows.Forms.MenuStrip
$form.MainMenuStrip = $menu

$miFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
$miOpenImg = New-Object System.Windows.Forms.ToolStripMenuItem("Open Image...")
$miSaveProj = New-Object System.Windows.Forms.ToolStripMenuItem("Save Project...")
$miLoadProj = New-Object System.Windows.Forms.ToolStripMenuItem("Load Project...")
$miExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$miFile.DropDownItems.AddRange(@($miOpenImg,$miSaveProj,$miLoadProj,$miExit))

$miView = New-Object System.Windows.Forms.ToolStripMenuItem("View")
$miToggleMarkers = New-Object System.Windows.Forms.ToolStripMenuItem("Show Markers") ; $miToggleMarkers.Checked = $true ; $miToggleMarkers.CheckOnClick = $true
$miToggleFOV     = New-Object System.Windows.Forms.ToolStripMenuItem("Show FOV")     ; $miToggleFOV.Checked     = $true ; $miToggleFOV.CheckOnClick     = $true
$miView.DropDownItems.AddRange(@($miToggleMarkers,$miToggleFOV))

$miLLM = New-Object System.Windows.Forms.ToolStripMenuItem("AI")
$miAnalyze = New-Object System.Windows.Forms.ToolStripMenuItem("Analyze with LLM")
$miLLM.DropDownItems.Add($miAnalyze)

$menu.Items.AddRange(@($miFile,$miView,$miLLM))
$form.Controls.Add($menu)

# Left: canvas
$pb = New-Object System.Windows.Forms.PictureBox
$pb.Dock = 'Fill'
$pb.BackColor = [System.Drawing.Color]::FromArgb(24,24,24)
$pb.SizeMode = 'Normal'
$form.Controls.Add($pb)

# Right: panel
$right = New-Object System.Windows.Forms.Panel
$right.Dock = 'Right'
$right.Width = 340
$right.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
$form.Controls.Add($right)
$right.BringToFront()

# Site notes
$lblNotes = New-Object System.Windows.Forms.Label
$lblNotes.Text = "Site notes"
$lblNotes.ForeColor = [System.Drawing.Color]::White
$lblNotes.Location = New-Object System.Drawing.Point(12,12)
$lblNotes.Size = New-Object System.Drawing.Size(200,20)
$tbSiteNotes = New-Object System.Windows.Forms.TextBox
$tbSiteNotes.Multiline = $true
$tbSiteNotes.ScrollBars = 'Vertical'
$tbSiteNotes.Location = New-Object System.Drawing.Point(12,36)
$tbSiteNotes.Size = New-Object System.Drawing.Size(316,120)
$tbSiteNotes.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
$tbSiteNotes.ForeColor = [System.Drawing.Color]::White
$tbSiteNotes.BorderStyle = 'FixedSingle'
$right.Controls.AddRange(@($lblNotes,$tbSiteNotes))

# Cameras list
$lblCams = New-Object System.Windows.Forms.Label
$lblCams.Text = "Cameras"
$lblCams.ForeColor = [System.Drawing.Color]::White
$lblCams.Location = New-Object System.Drawing.Point(12,168)
$lblCams.Size = New-Object System.Drawing.Size(200,20)
$lvCams = New-Object System.Windows.Forms.ListView
$lvCams.Location = New-Object System.Drawing.Point(12,192)
$lvCams.Size = New-Object System.Drawing.Size(316,220)
$lvCams.View = 'Details'
$lvCams.FullRowSelect = $true
$lvCams.GridLines = $true
$lvCams.Columns.Add("Id",40) | Out-Null
$lvCams.Columns.Add("Label",120) | Out-Null
$lvCams.Columns.Add("Lens",50) | Out-Null
$lvCams.Columns.Add("HFOV",50) | Out-Null
$lvCams.Columns.Add("Az",40) | Out-Null
$right.Controls.AddRange(@($lblCams,$lvCams))

# Buttons
$btnEdit = New-Object System.Windows.Forms.Button
$btnEdit.Text = "Edit"
$btnEdit.Location = New-Object System.Drawing.Point(12,420)
$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Remove"
$btnRemove.Location = New-Object System.Drawing.Point(96,420)
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export JSON"
$btnExport.Location = New-Object System.Drawing.Point(180,420)
$btnImport = New-Object System.Windows.Forms.Button
$btnImport.Text = "Import JSON"
$btnImport.Location = New-Object System.Drawing.Point(264,420)

$btnFit = New-Object System.Windows.Forms.Button
$btnFit.Text = "Fit to window"
$btnFit.Location = New-Object System.Drawing.Point(12,456)

$btnLLM = New-Object System.Windows.Forms.Button
$btnLLM.Text = "LLM Analyze"
$btnLLM.Location = New-Object System.Drawing.Point(120,456)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear cameras"
$btnClear.Location = New-Object System.Drawing.Point(228,456)

$right.Controls.AddRange(@($btnEdit,$btnRemove,$btnExport,$btnImport,$btnFit,$btnLLM,$btnClear))

# Output
$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = "AI output"
$lblOut.ForeColor = [System.Drawing.Color]::White
$lblOut.Location = New-Object System.Drawing.Point(12,492)
$lblOut.Size = New-Object System.Drawing.Size(200,20)
$tbOut = New-Object System.Windows.Forms.TextBox
$tbOut.Multiline = $true
$tbOut.ScrollBars = 'Vertical'
$tbOut.Location = New-Object System.Drawing.Point(12,516)
$tbOut.Size = New-Object System.Drawing.Size(316,240)
$tbOut.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
$tbOut.ForeColor = [System.Drawing.Color]::White
$tbOut.BorderStyle = 'FixedSingle'
$right.Controls.AddRange(@($lblOut,$tbOut))

# ==============================
# Events
# ==============================

function Refresh-List {
    $lvCams.Items.Clear()
    foreach ($c in $Global:Project.Cameras) {
        $item = New-Object System.Windows.Forms.ListViewItem($c.Id.ToString())
        $item.SubItems.Add($c.Label) | Out-Null
        $item.SubItems.Add("{0:0.0}mm" -f $c.LensMM) | Out-Null
        $item.SubItems.Add("{0:0}°" -f $c.HFOVDeg) | Out-Null
        $item.SubItems.Add("{0:0}°" -f $c.AzimuthDeg) | Out-Null
        $item.Tag = $c.Id
        $lvCams.Items.Add($item) | Out-Null
    }
}

$pb.Add_Paint({
    $g = $_.Graphics
    $g.SmoothingMode = 'AntiAlias'
    if ($Global:Image) {
        $g.DrawImage($Global:Image, $Global:Pan.X, $Global:Pan.Y, [int]($Global:Image.Width*$Global:Scale), [int]($Global:Image.Height*$Global:Scale))
    }
    if ($Global:Project.ShowFOV) {
        foreach ($c in $Global:Project.Cameras) { Draw-FOV -g $g -cam $c }
    }
    if ($Global:Project.ShowMarkers) {
        foreach ($c in $Global:Project.Cameras) { Draw-CameraMarker -g $g -cam $c }
    }
})

$pb.Add_Resize({ Fit-To-Window })

$pb.Add_MouseMove({
    $Global:HoverCamId = HitTest-CameraId -viewPt $_.Location
    $pb.Cursor = if ($Global:HoverCamId) { 'Hand' } else { 'Default' }
})

$pb.Add_MouseClick({
    $ptView = $_.Location
    $ptImg  = ViewToImagePoint $ptView
    if ($_.Button -eq 'Left') {
        $hitId = HitTest-CameraId -viewPt $ptView
        if ($hitId) {
            $cam = Get-CameraById $hitId
            if (Edit-CameraDialog -cam $cam) {
                Refresh-List
                $pb.Invalidate()
            }
        } else {
            $cam = New-Camera -X $ptImg.X -Y $ptImg.Y
            $Global:Project.Cameras += $cam
            Refresh-List
            $pb.Invalidate()
        }
    } elseif ($_.Button -eq 'Right') {
        $hitId = HitTest-CameraId -viewPt $ptView
        if ($hitId) {
            $cmenu = New-Object System.Windows.Forms.ContextMenuStrip
            $miEdit   = New-Object System.Windows.Forms.ToolStripMenuItem("Edit")
            $miDelete = New-Object System.Windows.Forms.ToolStripMenuItem("Delete")
            $miRotateL= New-Object System.Windows.Forms.ToolStripMenuItem("Rotate -10°")
            $miRotateR= New-Object System.Windows.Forms.ToolStripMenuItem("Rotate +10°")
            $cmenu.Items.AddRange(@($miEdit,$miDelete,$miRotateL,$miRotateR))
            $miEdit.Add_Click({ $cam = Get-CameraById $hitId; if (Edit-CameraDialog -cam $cam) { Refresh-List; $pb.Invalidate() } })
            $miDelete.Add_Click({ Remove-Camera -Id $hitId; Refresh-List; $pb.Invalidate() })
            $miRotateL.Add_Click({ $cam = Get-CameraById $hitId; $cam.AzimuthDeg -= 10; $pb.Invalidate() })
            $miRotateR.Add_Click({ $cam = Get-CameraById $hitId; $cam.AzimuthDeg += 10; $pb.Invalidate() })
            $cmenu.Show($pb,$ptView)
        }
    }
})

$miOpenImg.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Images (*.jpg;*.jpeg;*.png)|*.jpg;*.jpeg;*.png|All files (*.*)|*.*"
    $ofd.Title = "Open Site Image"
    if ($ofd.ShowDialog() -eq 'OK') {
        Load-Image $ofd.FileName
    }
})

$miSaveProj.Add_Click({ Save-Project })
$miLoadProj.Add_Click({ Load-Project })
$miExit.Add_Click({ $form.Close() })

$miToggleMarkers.Add_Click({
    $Global:Project.ShowMarkers = $miToggleMarkers.Checked
    $pb.Invalidate()
})
$miToggleFOV.Add_Click({
    $Global:Project.ShowFOV = $miToggleFOV.Checked
    $pb.Invalidate()
})

$btnEdit.Add_Click({
    if ($lvCams.SelectedItems.Count -gt 0) {
        $id = [int]$lvCams.SelectedItems[0].Tag
        $cam = Get-CameraById $id
        if (Edit-CameraDialog -cam $cam) { Refresh-List; $pb.Invalidate() }
    }
})

$btnRemove.Add_Click({
    if ($lvCams.SelectedItems.Count -gt 0) {
        $id = [int]$lvCams.SelectedItems[0].Tag
        Remove-Camera -Id $id
        Refresh-List; $pb.Invalidate()
    }
})

$btnExport.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "JSON (*.json)|*.json"
    $sfd.Title = "Export JSON"
    if ($sfd.ShowDialog() -eq 'OK') {
        [IO.File]::WriteAllText($sfd.FileName, (To-JSON (Build-LLMDataPayload)))
    }
})

$btnImport.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "JSON (*.json)|*.json"
    $ofd.Title = "Import JSON"
    if ($ofd.ShowDialog() -eq 'OK') {
        $data = From-JSON ([IO.File]::ReadAllText($ofd.FileName))
        if ($data.cameras) {
            $Global:Project.Cameras = @()
            $Global:NextId = 1
            foreach ($c in $data.cameras) {
                $cam = New-Camera -X $c.X -Y $c.Y -HeightM $c.HeightM -LensMM $c.LensMM -AzimuthDeg $c.AzimuthDeg -TiltDeg $c.TiltDeg -HFOVDeg $c.HFOVDeg -IR $c.IR -Resolution $c.Resolution -Label $c.Label
                $cam.Id = $c.Id
               
