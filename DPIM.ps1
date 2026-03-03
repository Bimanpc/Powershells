#!/usr/bin/pwsh

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-MonitorInfo {
    $xrandr = xrandr --query

    $primary = $xrandr | Select-String " connected primary"
    if (-not $primary) {
        $primary = $xrandr | Select-String " connected"
    }

    $res = [regex]::Match($primary, "(\d+)x(\d+)")
    $widthPx  = [int]$res.Groups[1].Value
    $heightPx = [int]$res.Groups[2].Value

    $size = [regex]::Match($primary, "(\d+)mm x (\d+)mm")
    $widthMM  = [int]$size.Groups[1].Value
    $heightMM = [int]$size.Groups[2].Value

    $widthIn  = $widthMM / 25.4
    $heightIn = $heightMM / 25.4

    $dpiX = [math]::Round($widthPx / $widthIn, 2)
    $dpiY = [math]::Round($heightPx / $heightIn, 2)
    $dpiAvg = [math]::Round((($dpiX + $dpiY) / 2), 2)

    return [PSCustomObject]@{
        WidthPx  = $widthPx
        HeightPx = $heightPx
        WidthMM  = $widthMM
        HeightMM = $heightMM
        DPI_X    = $dpiX
        DPI_Y    = $dpiY
        DPI_Avg  = $dpiAvg
    }
}

# GUI Window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ubuntu Monitor DPI Meter"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

$button = New-Object System.Windows.Forms.Button
$button.Text = "Measure DPI"
$button.Location = New-Object System.Drawing.Point(130, 20)
$button.Size = New-Object System.Drawing.Size(120, 40)
$form.Controls.Add($button)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 80)
$label.Size = New-Object System.Drawing.Size(350, 150)
$label.Font = New-Object System.Drawing.Font("Consolas", 11)
$form.Controls.Add($label)

$button.Add_Click({
    $info = Get-MonitorInfo
    $label.Text = @"
Resolution:   $($info.WidthPx)x$($info.HeightPx)
Size (mm):    $($info.WidthMM)mm x $($info.HeightMM)mm
DPI (X):      $($info.DPI_X)
DPI (Y):      $($info.DPI_Y)
DPI (Avg):    $($info.DPI_Avg)
"@
})

$form.ShowDialog()
