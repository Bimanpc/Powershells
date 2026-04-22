Add-Type -AssemblyName PresentationFramework

# --- COLOR THEME (Opera GX style) ---
$bg      = "#0A0A0F"
$panel   = "#13131A"
$neon    = "#FF0055"
$text    = "#E0E0E0"

# --- WINDOW ---
$win = New-Object System.Windows.Window
$win.Title = "Opera GX Speed & Stability Meter"
$win.Width = 520
$win.Height = 420
$win.Background = $bg
$win.WindowStartupLocation = "CenterScreen"

# --- GRID ---
$grid = New-Object System.Windows.Controls.Grid
$grid.Margin = "15"
$win.Content = $grid

# --- TITLE ---
$title = New-Object System.Windows.Controls.TextBlock
$title.Text = "GX SPEED + STABILITY"
$title.FontSize = 26
$title.Foreground = $neon
$title.Margin = "0,0,0,20"
$title.HorizontalAlignment = "Center"
$grid.Children.Add($title)

# --- SPEED LABELS ---
$dl = New-Object System.Windows.Controls.TextBlock
$dl.Text = "Download: -- Mbps"
$dl.FontSize = 20
$dl.Foreground = $text
$dl.Margin = "0,60,0,0"
$dl.HorizontalAlignment = "Center"
$grid.Children.Add($dl)

$ul = New-Object System.Windows.Controls.TextBlock
$ul.Text = "Upload: -- Mbps"
$ul.FontSize = 20
$ul.Foreground = $text
$ul.Margin = "0,110,0,0"
$ul.HorizontalAlignment = "Center"
$grid.Children.Add($ul)

# --- PING LABEL ---
$ping = New-Object System.Windows.Controls.TextBlock
$ping.Text = "Ping: -- ms"
$ping.FontSize = 20
$ping.Foreground = $text
$ping.Margin = "0,160,0,0"
$ping.HorizontalAlignment = "Center"
$grid.Children.Add($ping)

# --- STATUS ---
$status = New-Object System.Windows.Controls.TextBlock
$status.Text = "Status: Idle"
$status.FontSize = 18
$status.Foreground = $neon
$status.Margin = "0,210,0,0"
$status.HorizontalAlignment = "Center"
$grid.Children.Add($status)

# --- BUTTON ---
$btn = New-Object System.Windows.Controls.Button
$btn.Content = "RUN TEST"
$btn.Width = 160
$btn.Height = 40
$btn.Margin = "0,270,0,0"
$btn.HorizontalAlignment = "Center"
$btn.Background = $panel
$btn.Foreground = $neon
$btn.BorderBrush = $neon
$btn.FontSize = 18
$grid.Children.Add($btn)

# --- SPEED TEST FUNCTION ---
function Get-Speed {
    param($url = "https://speed.hetzner.de/100MB.bin")

    $tmp = "/tmp/gx_speed_test.bin"
    $wc = New-Object System.Net.WebClient

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $wc.DownloadFile($url, $tmp)
    } catch {
        return 0
    }
    $sw.Stop()

    $mb = (Get-Item $tmp).Length / 1MB
    Remove-Item $tmp -Force

    return [math]::Round($mb / ($sw.Elapsed.TotalSeconds), 2)
}

# --- PING FUNCTION ---
function Get-Ping {
    $p = Test-Connection -Count 1 -ComputerName "8.8.8.8" -ErrorAction SilentlyContinue
    if ($p) { return $p.Latency }
    return 0
}

# --- BUTTON CLICK ---
$btn.Add_Click({
    $status.Text = "Status: Running..."
    $dl.Text = "Download: testing..."
    $ul.Text = "Upload: testing..."
    $ping.Text = "Ping: testing..."

    Start-Job -ScriptBlock {
        $down = Get-Speed
        $up   = Get-Speed
        $lat  = Get-Ping
        return @{DL=$down; UL=$up; PING=$lat}
    } | Wait-Job | Receive-Job | ForEach-Object {
        $dl.Text   = "Download: $($_.DL) Mbps"
        $ul.Text   = "Upload: $($_.UL) Mbps"
        $ping.Text = "Ping: $($_.PING) ms"

        if ($_.PING -lt 40) { $status.Text = "Status: Excellent" }
        elseif ($_.PING -lt 80) { $status.Text = "Status: Good" }
        else { $status.Text = "Status: Poor" }
    }
})

$win.ShowDialog() | Out-Null
