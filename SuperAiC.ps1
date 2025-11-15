Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-AverageColor([System.Drawing.Bitmap] $bmp) {
    $width = $bmp.Width
    $height = $bmp.Height
    $r = 0; $g = 0; $b = 0
    for ($x=0; $x -lt $width; $x++) {
        for ($y=0; $y -lt $height; $y++) {
            $c = $bmp.GetPixel($x, $y)
            $r += $c.R; $g += $c.G; $b += $c.B
        }
    }
    $pixels = $width * $height
    return [System.Drawing.Color]::FromArgb([int]($r/$pixels), [int]($g/$pixels), [int]($b/$pixels))
}

function Resize-Bitmap([System.Drawing.Image] $img, [int] $w, [int] $h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $w, $h)
    $g.Dispose()
    return $bmp
}

function ColorDistance($c1, $c2) {
    $dr = $c1.R - $c2.R
    $dg = $c1.G - $c2.G
    $db = $c1.B - $c2.B
    return [math]::Sqrt($dr*$dr + $dg*$dg + $db*$db)
}

# Build UI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Photo Mosaic Creator"
$form.Size = New-Object System.Drawing.Size(640,420)
$form.StartPosition = "CenterScreen"

$lblTarget = New-Object System.Windows.Forms.Label
$lblTarget.Text = "Target Image"
$lblTarget.AutoSize = $true
$lblTarget.Location = New-Object System.Drawing.Point(12,12)
$form.Controls.Add($lblTarget)

$txtTarget = New-Object System.Windows.Forms.TextBox
$txtTarget.Location = New-Object System.Drawing.Point(12,30)
$txtTarget.Size = New-Object System.Drawing.Size(480,20)
$form.Controls.Add($txtTarget)

$btnBrowseTarget = New-Object System.Windows.Forms.Button
$btnBrowseTarget.Text = "Browse..."
$btnBrowseTarget.Location = New-Object System.Drawing.Point(500,28)
$btnBrowseTarget.Size = New-Object System.Drawing.Size(100,24)
$form.Controls.Add($btnBrowseTarget)

$lblTiles = New-Object System.Windows.Forms.Label
$lblTiles.Text = "Tiles Folder"
$lblTiles.AutoSize = $true
$lblTiles.Location = New-Object System.Drawing.Point(12,60)
$form.Controls.Add($lblTiles)

$txtTiles = New-Object System.Windows.Forms.TextBox
$txtTiles.Location = New-Object System.Drawing.Point(12,78)
$txtTiles.Size = New-Object System.Drawing.Size(480,20)
$form.Controls.Add($txtTiles)

$btnBrowseTiles = New-Object System.Windows.Forms.Button
$btnBrowseTiles.Text = "Browse..."
$btnBrowseTiles.Location = New-Object System.Drawing.Point(500,76)
$btnBrowseTiles.Size = New-Object System.Drawing.Size(100,24)
$form.Controls.Add($btnBrowseTiles)

$lblTileSize = New-Object System.Windows.Forms.Label
$lblTileSize.Text = "Tile Size (px)"
$lblTileSize.AutoSize = $true
$lblTileSize.Location = New-Object System.Drawing.Point(12,110)
$form.Controls.Add($lblTileSize)

$numTileSize = New-Object System.Windows.Forms.NumericUpDown
$numTileSize.Location = New-Object System.Drawing.Point(100,108)
$numTileSize.Minimum = 5
$numTileSize.Maximum = 500
$numTileSize.Value = 40
$form.Controls.Add($numTileSize)

$lblOverlap = New-Object System.Windows.Forms.Label
$lblOverlap.Text = "Overlap (px)"
$lblOverlap.AutoSize = $true
$lblOverlap.Location = New-Object System.Drawing.Point(12,140)
$form.Controls.Add($lblOverlap)

$numOverlap = New-Object System.Windows.Forms.NumericUpDown
$numOverlap.Location = New-Object System.Drawing.Point(100,138)
$numOverlap.Minimum = 0
$numOverlap.Maximum = 200
$numOverlap.Value = 0
$form.Controls.Add($numOverlap)

$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = "Output File"
$lblOutput.AutoSize = $true
$lblOutput.Location = New-Object System.Drawing.Point(12,170)
$form.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(12,188)
$txtOutput.Size = New-Object System.Drawing.Size(480,20)
$form.Controls.Add($txtOutput)

$btnBrowseOutput = New-Object System.Windows.Forms.Button
$btnBrowseOutput.Text = "Browse..."
$btnBrowseOutput.Location = New-Object System.Drawing.Point(500,186)
$btnBrowseOutput.Size = New-Object System.Drawing.Size(100,24)
$form.Controls.Add($btnBrowseOutput)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start"
$btnStart.Location = New-Object System.Drawing.Point(12,220)
$btnStart.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($btnStart)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(150,220)
$progress.Size = New-Object System.Drawing.Size(450,30)
$progress.Minimum = 0
$progress.Maximum = 100
$form.Controls.Add($progress)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(12,260)
$txtLog.Size = New-Object System.Drawing.Size(600,100)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$form.Controls.Add($txtLog)

# File pickers
$btnBrowseTarget.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Images|*.jpg;*.jpeg;*.png;*.bmp;*.gif"
    if ($ofd.ShowDialog() -eq "OK") { $txtTarget.Text = $ofd.FileName }
})

$btnBrowseTiles.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fbd.ShowDialog() -eq "OK") { $txtTiles.Text = $fbd.SelectedPath }
})

$btnBrowseOutput.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "PNG Image|*.png"
    $sfd.FileName = "mosaic.png"
    if ($sfd.ShowDialog() -eq "OK") { $txtOutput.Text = $sfd.FileName }
})

# Main generation
$btnStart.Add_Click({
    $targetPath = $txtTarget.Text.Trim()
    $tilesFolder = $txtTiles.Text.Trim()
    $tileSize = [int]$numTileSize.Value
    $overlap = [int]$numOverlap.Value
    $outPath = $txtOutput.Text.Trim()

    if (-not (Test-Path $targetPath)) { [System.Windows.Forms.MessageBox]::Show("Target image not found."); return }
    if (-not (Test-Path $tilesFolder)) { [System.Windows.Forms.MessageBox]::Show("Tiles folder not found."); return }
    if ([string]::IsNullOrWhiteSpace($outPath)) { [System.Windows.Forms.MessageBox]::Show("Set an output file."); return }

    $txtLog.AppendText("Loading tile images...`r`n")
    $tileFiles = Get-ChildItem -Path $tilesFolder -Include *.jpg,*.jpeg,*.png,*.bmp -File -Recurse | Select-Object -ExpandProperty FullName
    if ($tileFiles.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("No tile images found in folder."); return }

    # Preprocess tiles: load, resize to tileSize, compute average color
    $tileList = @()
    $idx = 0
    foreach ($f in $tileFiles) {
        try {
            $img = [System.Drawing.Image]::FromFile($f)
            $bmp = Resize-Bitmap $img $tileSize $tileSize
            $avg = Get-AverageColor $bmp
            $tileList += [pscustomobject]@{ Path = $f; Bitmap = $bmp; Avg = $avg }
            $img.Dispose()
        } catch {
            # skip bad images
        }
        $idx++
        if (($idx % 10) -eq 0) { $txtLog.AppendText("Processed $idx tiles...`r`n"); $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret() }
    }

    $txtLog.AppendText("Loaded $($tileList.Count) tiles.`r`n")

    # Load target
    $txtLog.AppendText("Loading target image...`r`n")
    $targetImg = [System.Drawing.Image]::FromFile($targetPath)
    $targetBmp = New-Object System.Drawing.Bitmap $targetImg
    $targetImg.Dispose()

    $outWidth = $targetBmp.Width
    $outHeight = $targetBmp.Height

    # compute grid
    $step = $tileSize - $overlap
    if ($step -le 0) { [System.Windows.Forms.MessageBox]::Show("Overlap must be less than tile size."); return }
    $cols = [math]::Ceiling($outWidth / $step)
    $rows = [math]::Ceiling($outHeight / $step)

    $txtLog.AppendText("Target size: ${outWidth}x${outHeight}; Grid: ${cols}x${rows}`r`n")

    $result = New-Object System.Drawing.Bitmap $outWidth, $outHeight
    $gRes = [System.Drawing.Graphics]::FromImage($result)
    $gRes.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $progress.Value = 0
    $total = $cols * $rows
    $count = 0

    for ($r=0; $r -lt $rows; $r++) {
        for ($c=0; $c -lt $cols; $c++) {
            $x = [int]($c * $step)
            $y = [int]($r * $step)
            $rectW = [math]::Min($tileSize, $outWidth - $x)
            $rectH = [math]::Min($tileSize, $outHeight - $y)
            $srcRect = New-Object System.Drawing.Rectangle $x, $y, $rectW, $rectH

            $cropBmp = New-Object System.Drawing.Bitmap $rectW, $rectH
            $gCrop = [System.Drawing.Graphics]::FromImage($cropBmp)
            $gCrop.DrawImage($targetBmp, 0, 0, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
            $gCrop.Dispose()
            $avgColor = Get-AverageColor $cropBmp
            $cropBmp.Dispose()

            # find nearest tile
            $best = $null; $bestDist = [double]::MaxValue
            foreach ($t in $tileList) {
                $d = ColorDistance $avgColor $t.Avg
                if ($d -lt $bestDist) { $bestDist = $d; $best = $t }
            }

            if ($best -ne $null) {
                # draw tile (resize if needed to match rectW/rectH)
                if ($best.Bitmap.Width -ne $rectW -or $best.Bitmap.Height -ne $rectH) {
                    $tileToDraw = Resize-Bitmap $best.Bitmap $rectW $rectH
                    $gRes.DrawImage($tileToDraw, $x, $y, $rectW, $rectH)
                    $tileToDraw.Dispose()
                } else {
                    $gRes.DrawImage($best.Bitmap, $x, $y, $rectW, $rectH)
                }
            }
            $count++
            $progress.Value = [int](($count / $total) * 100)
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    $gRes.Dispose()
    $targetBmp.Dispose()

    # Save result
    try {
        $txtLog.AppendText("Saving result to $outPath`r`n")
        $result.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $result.Dispose()
        [System.Windows.Forms.MessageBox]::Show("Mosaic created.") 
        $txtLog.AppendText("Done.`r`n")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to save: $($_.Exception.Message)")
    }
})

$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
