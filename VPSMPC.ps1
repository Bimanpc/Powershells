Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mini MPC"
$form.Width = 900
$form.Height = 600
$form.StartPosition = "CenterScreen"
$form.KeyPreview = $true

# --- Menu ---
$menu = New-Object System.Windows.Forms.MenuStrip
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("File")
$openItem = New-Object System.Windows.Forms.ToolStripMenuItem("Open...")
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$fileMenu.DropDownItems.AddRange(@($openItem, $exitItem))
$menu.Items.Add($fileMenu)
$form.Controls.Add($menu)

# --- Windows Media Player ActiveX ---
$ax = New-Object System.Windows.Forms.Integration.ElementHost
$ax.Dock = "Fill"

$wmp = New-Object -ComObject WMPlayer.OCX
$ax.Child = $wmp

$form.Controls.Add($ax)

# --- Control Panel ---
$panel = New-Object System.Windows.Forms.Panel
$panel.Height = 60
$panel.Dock = "Bottom"
$panel.BackColor = "Black"

# Buttons
$btnPlay = New-Object System.Windows.Forms.Button
$btnPlay.Text = "Play"
$btnPlay.Width = 60
$btnPlay.Location = "10,15"

$btnPause = New-Object System.Windows.Forms.Button
$btnPause.Text = "Pause"
$btnPause.Width = 60
$btnPause.Location = "80,15"

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Stop"
$btnStop.Width = 60
$btnStop.Location = "150,15"

# Seek bar
$seek = New-Object System.Windows.Forms.TrackBar
$seek.Minimum = 0
$seek.Maximum = 1000
$seek.TickStyle = "None"
$seek.Width = 400
$seek.Location = "230,10"

# Volume slider
$vol = New-Object System.Windows.Forms.TrackBar
$vol.Minimum = 0
$vol.Maximum = 100
$vol.Value = 50
$vol.TickStyle = "None"
$vol.Width = 120
$vol.Location = "650,10"

$panel.Controls.AddRange(@($btnPlay,$btnPause,$btnStop,$seek,$vol))
$form.Controls.Add($panel)

# --- Timer for updating seek bar ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

# --- Event Handlers ---

$openItem.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Media Files|*.mp4;*.mp3;*.avi;*.mkv;*.wav;*.wmv|All Files|*.*"
    if ($ofd.ShowDialog() -eq "OK") {
        $wmp.URL = $ofd.FileName
        $wmp.controls.play()
        $form.Text = "Mini MPC - " + (Split-Path $ofd.FileName -Leaf)
    }
})

$exitItem.Add_Click({ $form.Close() })

$btnPlay.Add_Click({ $wmp.controls.play() })
$btnPause.Add_Click({ $wmp.controls.pause() })
$btnStop.Add_Click({ $wmp.controls.stop() })

$vol.Add_Scroll({
    $wmp.settings.volume = $vol.Value
})

$seek.Add_MouseUp({
    if ($wmp.currentMedia.duration -gt 0) {
        $pos = ($seek.Value / 1000) * $wmp.currentMedia.duration
        $wmp.controls.currentPosition = $pos
    }
})

$timer.Add_Tick({
    if ($wmp.playState -eq 3 -and $wmp.currentMedia.duration -gt 0) {
        $seek.Value = [int](1000 * ($wmp.controls.currentPosition / $wmp.currentMedia.duration))
    }
})

$timer.Start()

# Fullscreen toggle (double‑click)
$form.Add_MouseDoubleClick({
    if ($wmp.fullScreen -eq $false) {
        $wmp.fullScreen = $true
    }
})

[void]$form.ShowDialog()
