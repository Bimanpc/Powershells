#requires -version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# Load Windows Media Player ActiveX
$code = @"
using System;
using System.Windows.Forms;
using AxWMPLib;
public class WmpHost : Form {
    public AxWindowsMediaPlayer Player;
    public WmpHost() {
        Player = new AxWindowsMediaPlayer();
        Player.BeginInit();
        Player.Dock = DockStyle.Fill;
        Controls.Add(Player);
        Player.EndInit();
    }
}
"@
Add-Type -ReferencedAssemblies @("System.Windows.Forms.dll","System.Drawing.dll","AxInterop.WMPLib.dll","Interop.WMPLib.dll") -TypeDefinition $code -ErrorAction SilentlyContinue
if (-not ([Type]::GetType("AxWMPLib.AxWindowsMediaPlayer"))) {
    # Fallback compile via COM if interop isn't present
    $code2 = @"
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;

[ComImport, Guid("6BF52A52-394A-11D3-B153-00C04F79FAA6")]
public class WindowsMediaPlayer {}

public class AxHostWmp : AxHost {
    public AxHostWmp(): base("6BF52A52-394A-11D3-B153-00C04F79FAA6") {}
}
"@
    Add-Type -TypeDefinition $code2 -ReferencedAssemblies @("System.Windows.Forms.dll","System.Drawing.dll")
}

# --- Globals ---
$Form              = New-Object System.Windows.Forms.Form
$Form.Text         = "Winamp-like Player + AI DJ"
$Form.StartPosition= "CenterScreen"
$Form.Width        = 1100
$Form.Height       = 700

$Split             = New-Object System.Windows.Forms.SplitContainer
$Split.Dock        = "Fill"
$Split.SplitterDistance = 360
$Form.Controls.Add($Split)

# Left panel: playlist & library controls
$PanelLeft         = $Split.Panel1
$PanelRight        = $Split.Panel2

$TopBar            = New-Object System.Windows.Forms.Panel
$TopBar.Dock       = "Top"
$TopBar.Height     = 48
$PanelLeft.Controls.Add($TopBar)

$BtnOpenFiles      = New-Object System.Windows.Forms.Button
$BtnOpenFiles.Text = "Add files"
$BtnOpenFiles.Width= 90
$BtnOpenFiles.Left = 8
$BtnOpenFiles.Top  = 10
$TopBar.Controls.Add($BtnOpenFiles)

$BtnOpenFolder      = New-Object System.Windows.Forms.Button
$BtnOpenFolder.Text = "Add folder"
$BtnOpenFolder.Width= 90
$BtnOpenFolder.Left = 108
$BtnOpenFolder.Top  = 10
$TopBar.Controls.Add($BtnOpenFolder)

$BtnClear          = New-Object System.Windows.Forms.Button
$BtnClear.Text     = "Clear"
$BtnClear.Width    = 70
$BtnClear.Left     = 208
$BtnClear.Top      = 10
$TopBar.Controls.Add($BtnClear)

$BtnShuffle        = New-Object System.Windows.Forms.Button
$BtnShuffle.Text   = "Shuffle"
$BtnShuffle.Width  = 80
$BtnShuffle.Left   = 288
$BtnShuffle.Top    = 10
$TopBar.Controls.Add($BtnShuffle)

$Playlist          = New-Object System.Windows.Forms.ListView
$Playlist.View     = 'Details'
$Playlist.FullRowSelect = $true
$Playlist.GridLines= $true
$Playlist.Dock     = "Fill"
$Playlist.Columns.Add("Title", 190) | Out-Null
$Playlist.Columns.Add("Artist", 120) | Out-Null
$Playlist.Columns.Add("Album", 120) | Out-Null
$Playlist.Columns.Add("Duration", 80) | Out-Null
$Playlist.Columns.Add("Path", 0) | Out-Null
$PanelLeft.Controls.Add($Playlist)

# Right side: WMP host + transport + AI panel
$PlayerHostPanel   = New-Object System.Windows.Forms.Panel
$PlayerHostPanel.Dock = "Top"
$PlayerHostPanel.Height= 380
$PanelRight.Controls.Add($PlayerHostPanel)

# Embed WMP ActiveX
$Wmp = New-Object System.Windows.Forms.Integration.ElementHost
$Wmp.Visible = $false # ElementHost not needed if we use Ax host directly; we'll add control below.

# Try AxWindowsMediaPlayer directly via AxHost
$Ax = New-Object AxWMPLib.AxWindowsMediaPlayer
$Ax.BeginInit()
$Ax.Dock = 'Fill'
$PlayerHostPanel.Controls.Add($Ax)
$Ax.EndInit()

# Transport panel
$Transport         = New-Object System.Windows.Forms.Panel
$Transport.Dock    = "Top"
$Transport.Height  = 120
$PanelRight.Controls.Add($Transport)

$LblNowPlaying     = New-Object System.Windows.Forms.Label
$LblNowPlaying.Text= "Now Playing: —"
$LblNowPlaying.AutoSize = $true
$LblNowPlaying.Left= 12
$LblNowPlaying.Top = 10
$Transport.Controls.Add($LblNowPlaying)

$BtnPrev           = New-Object System.Windows.Forms.Button
$BtnPrev.Text      = "⏮ Prev"
$BtnPrev.Left      = 12
$BtnPrev.Top       = 40
$BtnPrev.Width     = 80
$Transport.Controls.Add($BtnPrev)

$BtnPlayPause      = New-Object System.Windows.Forms.Button
$BtnPlayPause.Text = "▶ Play"
$BtnPlayPause.Left = 100
$BtnPlayPause.Top  = 40
$BtnPlayPause.Width= 90
$Transport.Controls.Add($BtnPlayPause)

$BtnStop           = New-Object System.Windows.Forms.Button
$BtnStop.Text      = "⏹ Stop"
$BtnStop.Left      = 200
$BtnStop.Top       = 40
$BtnStop.Width     = 80
$Transport.Controls.Add($BtnStop)

$BtnNext           = New-Object System.Windows.Forms.Button
$BtnNext.Text      = "⏭ Next"
$BtnNext.Left      = 290
$BtnNext.Top       = 40
$BtnNext.Width     = 80
$Transport.Controls.Add($BtnNext)

$LblVol            = New-Object System.Windows.Forms.Label
$LblVol.Text       = "Volume"
$LblVol.Left       = 380
$LblVol.Top        = 44
$Transport.Controls.Add($LblVol)

$Vol               = New-Object System.Windows.Forms.TrackBar
$Vol.Minimum       = 0
$Vol.Maximum       = 100
$Vol.Value         = 70
$Vol.TickFrequency = 10
$Vol.Left          = 440
$Vol.Top           = 40
$Vol.Width         = 160
$Transport.Controls.Add($Vol)

$Seek              = New-Object System.Windows.Forms.TrackBar
$Seek.Minimum      = 0
$Seek.Maximum      = 1000
$Seek.Value        = 0
$Seek.TickStyle    = 'None'
$Seek.Left         = 12
$Seek.Top          = 80
$Seek.Width        = 588
$Transport.Controls.Add($Seek)

$LblTime           = New-Object System.Windows.Forms.Label
$LblTime.Text      = "00:00 / 00:00"
$LblTime.AutoSize  = $true
$LblTime.Left      = 612
$LblTime.Top       = 82
$Transport.Controls.Add($LblTime)

# AI DJ panel
$AIPanel           = New-Object System.Windows.Forms.Panel
$AIPanel.Dock      = "Fill"
$PanelRight.Controls.Add($AIPanel)

$LblAI             = New-Object System.Windows.Forms.Label
$LblAI.Text        = "AI DJ Prompt (mood, genre, tempo, vibe):"
$LblAI.AutoSize    = $true
$LblAI.Left        = 12
$LblAI.Top         = 10
$AIPanel.Controls.Add($LblAI)

$TxtPrompt         = New-Object System.Windows.Forms.TextBox
$TxtPrompt.Left    = 12
$TxtPrompt.Top     = 32
$TxtPrompt.Width   = 760
$TxtPrompt.Height  = 60
$TxtPrompt.Multiline = $true
$AIPanel.Controls.Add($TxtPrompt)

$BtnAIGenerate     = New-Object System.Windows.Forms.Button
$BtnAIGenerate.Text= "🎛 Generate AI Playlist"
$BtnAIGenerate.Left= 12
$BtnAIGenerate.Top = 100
$BtnAIGenerate.Width= 180
$AIPanel.Controls.Add($BtnAIGenerate)

$BtnAITitle        = New-Object System.Windows.Forms.Button
$BtnAITitle.Text   = "🧠 Suggest Title/Tags"
$BtnAITitle.Left   = 204
$BtnAITitle.Top    = 100
$BtnAITitle.Width  = 160
$AIPanel.Controls.Add($BtnAITitle)

$TxtAIOut          = New-Object System.Windows.Forms.TextBox
$TxtAIOut.Left     = 12
$TxtAIOut.Top      = 140
$TxtAIOut.Width    = 760
$TxtAIOut.Height   = 180
$TxtAIOut.Multiline= $true
$TxtAIOut.ScrollBars = 'Vertical'
$AIPanel.Controls.Add($TxtAIOut)

# --- State ---
$Library = New-Object System.Collections.ArrayList
$CurrentIndex = -1
$IsSeeking = $false
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 500

function Get-AudioMetadata {
    param([string]$Path)
    # Basic metadata from filename; WMP will populate richer tags once loaded
    $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $artist = ""
    $album = ""
    $title = $name
    $duration = ""
    [PSCustomObject]@{
        Title    = $title
        Artist   = $artist
        Album    = $album
        Duration = $duration
        Path     = $Path
    }
}

function Add-ToPlaylist {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        if (-not [string]::IsNullOrWhiteSpace($p) -and (Test-Path $p)) {
            $meta = Get-AudioMetadata -Path $p
            $Library.Add($meta) | Out-Null
            $item = New-Object System.Windows.Forms.ListViewItem($meta.Title)
            $item.SubItems.Add($meta.Artist) | Out-Null
            $item.SubItems.Add($meta.Album) | Out-Null
            $item.SubItems.Add($meta.Duration) | Out-Null
            $item.SubItems.Add($meta.Path) | Out-Null
            $Playlist.Items.Add($item) | Out-Null
        }
    }
    if ($CurrentIndex -lt 0 -and $Library.Count -gt 0) { Set-CurrentIndex 0 }
}

function Set-CurrentIndex {
    param([int]$Index)
    if ($Index -lt 0 -or $Index -ge $Library.Count) { return }
    $CurrentIndex = $Index
    for ($i=0; $i -lt $Playlist.Items.Count; $i++) {
        $Playlist.Items[$i].BackColor = [System.Drawing.Color]::White
    }
    $Playlist.Items[$Index].BackColor = [System.Drawing.Color]::LightYellow

    $track = $Library[$Index]
    $Ax.URL = $track.Path
    $LblNowPlaying.Text = "Now Playing: " + ($track.Title)
    $BtnPlayPause.Text = "⏸ Pause"
}

function PlayCurrent { if ($CurrentIndex -ge 0) { $Ax.Ctlcontrols.play(); $BtnPlayPause.Text = "⏸ Pause" } }
function PauseCurrent { $Ax.Ctlcontrols.pause(); $BtnPlayPause.Text = "▶ Play" }
function StopCurrent  { $Ax.Ctlcontrols.stop();  $BtnPlayPause.Text = "▶ Play" }

function NextTrack {
    if ($Library.Count -eq 0) { return }
    $idx = ($CurrentIndex + 1)
    if ($idx -ge $Library.Count) { $idx = 0 }
    Set-CurrentIndex $idx
    PlayCurrent
}

function PrevTrack {
    if ($Library.Count -eq 0) { return }
    $idx = ($CurrentIndex - 1)
    if ($idx -lt 0) { $idx = $Library.Count - 1 }
    Set-CurrentIndex $idx
    PlayCurrent
}

function TimeFmt([double]$sec) {
    if ($sec -lt 0) { $sec = 0 }
    $m = [math]::Floor($sec / 60)
    $s = [math]::Floor($sec % 60)
    "{0:00}:{1:00}" -f $m,$s
}

# --- Events ---
$BtnOpenFiles.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Multiselect = $true
    $dlg.Filter = "Audio|*.mp3;*.wav;*.aac;*.wma;*.m4a;*.ogg|All Files|*.*"
    if ($dlg.ShowDialog() -eq 'OK') { Add-ToPlaylist $dlg.FileNames }
})

$BtnOpenFolder.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fbd.ShowDialog() -eq 'OK') {
        $paths = Get-ChildItem -Path $fbd.SelectedPath -File -Recurse -Include *.mp3,*.wav,*.aac,*.wma,*.m4a,*.ogg | Select-Object -ExpandProperty FullName
        Add-ToPlaylist $paths
    }
})

$BtnClear.Add_Click({
    $Library.Clear()
    $Playlist.Items.Clear()
    $CurrentIndex = -1
    StopCurrent
    $LblNowPlaying.Text = "Now Playing: —"
    $LblTime.Text = "00:00 / 00:00"
    $Seek.Value = 0
})

$BtnShuffle.Add_Click({
    if ($Library.Count -gt 1) {
        $shuffled = $Library | Get-Random -Count $Library.Count
        $Library = [System.Collections.ArrayList]::new()
        $Playlist.Items.Clear()
        foreach ($t in $shuffled) {
            $Library.Add($t) | Out-Null
            $item = New-Object System.Windows.Forms.ListViewItem($t.Title)
            $item.SubItems.Add($t.Artist) | Out-Null
            $item.SubItems.Add($t.Album) | Out-Null
            $item.SubItems.Add($t.Duration) | Out-Null
            $item.SubItems.Add($t.Path) | Out-Null
            $Playlist.Items.Add($item) | Out-Null
        }
        Set-CurrentIndex 0
    }
})

$Playlist.Add_DoubleClick({
    if ($Playlist.SelectedIndices.Count -gt 0) {
        Set-CurrentIndex $Playlist.SelectedIndices[0]
        PlayCurrent
    }
})

$BtnPlayPause.Add_Click({
    if ($CurrentIndex -lt 0 -and $Library.Count -gt 0) { Set-CurrentIndex 0 }
    if ($Ax.playState -eq 2 -or $Ax.playState -eq 1) { PlayCurrent } else { PauseCurrent }
})

$BtnStop.Add_Click({ StopCurrent })
$BtnNext.Add_Click({ NextTrack })
$BtnPrev.Add_Click({ PrevTrack })

$Vol.Add_Scroll({ $Ax.settings.volume = $Vol.Value })

$Seek.Add_MouseDown({ $global:IsSeeking = $true })
$Seek.Add_MouseUp({
    $global:IsSeeking = $false
    try {
        $dur = [double]$Ax.currentMedia.duration
        if ($dur -gt 0) {
            $target = ($Seek.Value / $Seek.Maximum) * $dur
            $Ax.Ctlcontrols.currentPosition = $target
        }
    } catch {}
})

$Timer.Add_Tick({
    try {
        $dur = [double]$Ax.currentMedia.duration
        $pos = [double]$Ax.Ctlcontrols.currentPosition
        if (-not $global:IsSeeking -and $dur -gt 0) {
            $Seek.Value = [int](($pos / $dur) * $Seek.Maximum)
        }
        $LblTime.Text = "$(TimeFmt($pos)) / $(TimeFmt($dur))"
        # Auto-next at end
        if ($Ax.playState -eq 1 -and $Library.Count -gt 0) {
            NextTrack
        }
        # Update metadata after load
        if ($CurrentIndex -ge 0 -and $Ax.currentMedia) {
            $meta = $Library[$CurrentIndex]
            $meta.Title  = $Ax.currentMedia.getItemInfo("Title")
            $meta.Artist = $Ax.currentMedia.getItemInfo("Artist")
            $meta.Album  = $Ax.currentMedia.getItemInfo("Album")
            $meta.Duration = TimeFmt([double]$Ax.currentMedia.duration)
            $Playlist.Items[$CurrentIndex].Text = $meta.Title
            $Playlist.Items[$CurrentIndex].SubItems[1].Text = $meta.Artist
            $Playlist.Items[$CurrentIndex].SubItems[2].Text = $meta.Album
            $Playlist.Items[$CurrentIndex].SubItems[3].Text = $meta.Duration
        }
    } catch {}
})
$Timer.Start()

# --- AI LLM features (stub with local logic + optional REST call) ---

function Invoke-AIPlaylist {
    param(
        [string]$Prompt,
        [PSObject[]]$Tracks,
        [string]$ApiUrl = $env:LLM_API_URL,
        [string]$ApiKey = $env:LLM_API_KEY
    )
    # If no external endpoint, do a local heuristic: filter and sort by keywords from prompt.
    if ([string]::IsNullOrWhiteSpace($ApiUrl) -or [string]::IsNullOrWhiteSpace($ApiKey)) {
        $keywords = ($Prompt -split '\W+' | Where-Object { $_ }) | ForEach-Object { $_.ToLower() }
        $score = {
            param($t)
            $s = 0
            foreach ($k in $keywords) {
                if ($t.Title -and $t.Title.ToLower().Contains($k)) { $s += 2 }
                if ($t.Artist -and $t.Artist.ToLower().Contains($k)) { $s += 1 }
                if ($t.Album  -and $t.Album.ToLower().Contains($k))  { $s += 1 }
            }
            return $s
        }
        return ($Tracks | Sort-Object @{Expression=$score; Descending=$true})
    }

    # Optional: call your LLM endpoint for smarter sequencing (JSON in/out)
    try {
        $payload = @{
            prompt = "Reorder these tracks into a cohesive playlist for: $Prompt. Return JSON array of indices."
            tracks = ($Tracks | ForEach-Object {
                @{
                    title  = $_.Title
                    artist = $_.Artist
                    album  = $_.Album
                }
            })
        } | ConvertTo-Json -Depth 4

        $resp = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers @{ "Authorization"="Bearer $ApiKey"; "Content-Type"="application/json" } -Body $payload
        if ($resp -and $resp.indices) {
            $order = @()
            foreach ($i in $resp.indices) { if ($i -ge 0 -and $i -lt $Tracks.Count) { $order += $Tracks[$i] } }
            if ($order.Count -gt 0) { return $order }
        }
    } catch {
        # Fallback to heuristic on error
        return Invoke-AIPlaylist -Prompt $Prompt -Tracks $Tracks
    }
}

function Invoke-AITags {
    param([string]$Prompt,[PSObject]$Track)
    # Local suggestion: combine mood and simple tags
    $mood = ($Prompt -replace '[^\w\s-]','').Trim()
    $base = @()
    if ($Track.Artist) { $base += $Track.Artist }
    if ($Track.Album)  { $base += $Track.Album }
    $base += ($Track.Title)
    $tags = @("mood:$mood","year:$(Get-Date -Format yyyy)","playlist:auto","ai:dj")
    [string]::Join(", ", ($base + $tags))
}

$BtnAIGenerate.Add_Click({
    if ($Library.Count -eq 0) { return }
    $TxtAIOut.Text = "Thinking..."
    $ordered = Invoke-AIPlaylist -Prompt $TxtPrompt.Text -Tracks $Library
    if ($ordered -and $ordered.Count -gt 0) {
        # Rebuild playlist view in new order
        $Library = [System.Collections.ArrayList]::new()
        $Playlist.Items.Clear()
        foreach ($t in $ordered) {
            $Library.Add($t) | Out-Null
            $item = New-Object System.Windows.Forms.ListViewItem($t.Title)
            $item.SubItems.Add($t.Artist) | Out-Null
            $item.SubItems.Add($t.Album) | Out-Null
            $item.SubItems.Add($t.Duration) | Out-Null
            $item.SubItems.Add($t.Path) | Out-Null
            $Playlist.Items.Add($item) | Out-Null
        }
        Set-CurrentIndex 0
        PlayCurrent
        $TxtAIOut.Text = "AI Playlist generated for: `"$($TxtPrompt.Text)`" (`$env:LLM_API_URL used: $([string]::IsNullOrWhiteSpace($env:LLM_API_URL) -eq $false))"
    } else {
        $TxtAIOut.Text = "No result. Try adding more files or a clearer prompt."
    }
})

$BtnAITitle.Add_Click({
    if ($CurrentIndex -lt 0) { return }
    $t = $Library[$CurrentIndex]
    $suggest = Invoke-AITags -Prompt $TxtPrompt.Text -Track $t
    $TxtAIOut.Text = "Suggested title/tags:`r`n$suggest"
})

# --- Keyboard shortcuts ---
$Form.Add_KeyDown({
    switch ($_.KeyCode) {
        'Space' { if ($Ax.playState -eq 2 -or $Ax.playState -eq 1) { PlayCurrent } else { PauseCurrent }; $_.SuppressKeyPress = $true }
        'Right' { NextTrack; $_.SuppressKeyPress = $true }
        'Left'  { PrevTrack; $_.SuppressKeyPress = $true }
        'Up'    { $Vol.Value = [math]::Min($Vol.Value+5, $Vol.Maximum); $Ax.settings.volume = $Vol.Value }
        'Down'  { $Vol.Value = [math]::Max($Vol.Value-5, $Vol.Minimum); $Ax.settings.volume = $Vol.Value }
    }
})

# --- Skin-like tweaks ---
$Form.BackColor           = [System.Drawing.Color]::FromArgb(30,30,30)
$PanelLeft.BackColor      = [System.Drawing.Color]::FromArgb(24,24,24)
$TopBar.BackColor         = [System.Drawing.Color]::FromArgb(40,40,40)
$Playlist.BackColor       = [System.Drawing.Color]::FromArgb(20,20,20)
$Playlist.ForeColor       = [System.Drawing.Color]::White
$PanelRight.BackColor     = [System.Drawing.Color]::FromArgb(24,24,24)
$Transport.BackColor      = [System.Drawing.Color]::FromArgb(40,40,40)
$AIPanel.BackColor        = [System.Drawing.Color]::FromArgb(30,30,30)
$LblNowPlaying.ForeColor  = [System.Drawing.Color]::White
$LblTime.ForeColor        = [System.Drawing.Color]::Gainsboro
$LblAI.ForeColor          = [System.Drawing.Color]::White
$TxtPrompt.BackColor      = [System.Drawing.Color]::FromArgb(18,18,18)
$TxtPrompt.ForeColor      = [System.Drawing.Color]::White
$TxtAIOut.BackColor       = [System.Drawing.Color]::FromArgb(18,18,18)
$TxtAIOut.ForeColor       = [System.Drawing.Color]::White

# Show
$Form.KeyPreview = $true
[void]$Form.ShowDialog()
