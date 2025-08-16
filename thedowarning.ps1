<# 
NetworkWatchdog.ps1
A simple PowerShell WinForms GUI to monitor network hosts via ICMP ping.
Run with: powershell.exe -STA -ExecutionPolicy Bypass -File .\NetworkWatchdog.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Media

#-------------------------
# Helpers
#-------------------------
function New-ListViewColumn {
    param(
        [Parameter(Mandatory)] [System.Windows.Forms.ListView] $ListView,
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [int] $Width
    )
    $col = New-Object System.Windows.Forms.ColumnHeader
    $col.Text = $Text
    $col.Width = $Width
    $ListView.Columns.Add($col) | Out-Null
}

function Test-Host {
    param(
        [Parameter(Mandatory)] [string] $Host,
        [Parameter(Mandatory)] [int] $TimeoutMs
    )
    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $reply = $ping.Send($Host, $TimeoutMs)
        if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
            [pscustomobject]@{
                Host      = $Host
                Success   = $true
                Roundtrip = [int]$reply.RoundtripTime
                Address   = $reply.Address.IPAddressToString
                Message   = "OK"
            }
        } else {
            [pscustomobject]@{
                Host      = $Host
                Success   = $false
                Roundtrip = $null
                Address   = $null
                Message   = $reply.Status.ToString()
            }
        }
    } catch {
        [pscustomobject]@{
            Host      = $Host
            Success   = $false
            Roundtrip = $null
            Address   = $null
            Message   = $_.Exception.Message
        }
    } finally {
        $ping.Dispose()
    }
}

function Add-LogRow {
    param(
        [Parameter(Mandatory)] [string] $Timestamp,
        [Parameter(Mandatory)] [string] $Host,
        [Parameter(Mandatory)] [string] $LatencyText,
        [Parameter(Mandatory)] [string] $StatusText,
        [Parameter(Mandatory)] [string] $Message
    )
    $item = New-Object System.Windows.Forms.ListViewItem($Timestamp)
    $item.SubItems.Add($Host)       | Out-Null
    $item.SubItems.Add($LatencyText)| Out-Null
    $item.SubItems.Add($StatusText) | Out-Null
    $item.SubItems.Add($Message)    | Out-Null

    # Color by status
    if ($StatusText -eq 'UP') {
        $item.ForeColor = [System.Drawing.Color]::FromArgb(0, 128, 0) # green
    } else {
        $item.ForeColor = [System.Drawing.Color]::FromArgb(192, 0, 0) # red
    }

    $global:lvLog.BeginUpdate()
    [void]$global:lvLog.Items.Insert(0, $item)
    $global:lvLog.EndUpdate()

    if ($global:cbLogToFile.Checked -and [IO.Path]::GetExtension($global:txtLogFile.Text) -ne '') {
        $line = '"' + ($Timestamp.Replace('"','""')) + '","' + ($Host.Replace('"','""')) + '","' + ($LatencyText.Replace('"','""')) + '","' + ($StatusText.Replace('"','""')) + '","' + ($Message.Replace('"','""')) + '"'
        Add-Content -Path $global:txtLogFile.Text -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    }
}

function Show-Notify {
    param(
        [Parameter(Mandatory)] [string] $Title,
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [System.Windows.Forms.ToolTipIcon] $Icon
    )
    if ($global:cbTrayNotify.Checked) {
        $global:notifyIcon.BalloonTipTitle = $Title
        $global:notifyIcon.BalloonTipText  = $Text
        $global:notifyIcon.BalloonTipIcon  = $Icon
        $global:notifyIcon.ShowBalloonTip(3000)
    }
}

function Pick-LogFile {
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
    $dlg.Title  = "Choose log file"
    $dlg.FileName = "NetworkWatchdogLog.csv"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $global:txtLogFile.Text = $dlg.FileName
        if (!(Test-Path $dlg.FileName)) {
            '"Timestamp","Host","Latency(ms)","Status","Message"' | Set-Content -Path $dlg.FileName -Encoding UTF8
        }
    }
}

#-------------------------
# Form and controls
#-------------------------
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "Network Watchdog"
$form.StartPosition   = "CenterScreen"
$form.Size            = New-Object System.Drawing.Size(920, 620)
$form.MinimumSize     = New-Object System.Drawing.Size(820, 520)

# Host input
$lblHost              = New-Object System.Windows.Forms.Label
$lblHost.Text         = "Host/IP:"
$lblHost.Location     = "12,15"
$lblHost.AutoSize     = $true

$txtHost              = New-Object System.Windows.Forms.TextBox
$txtHost.Location     = "70,12"
$txtHost.Size         = New-Object System.Drawing.Size(260, 24)

$btnAddHost           = New-Object System.Windows.Forms.Button
$btnAddHost.Text      = "Add"
$btnAddHost.Location  = "340,10"
$btnAddHost.Size      = New-Object System.Drawing.Size(60,28)

$lbHosts              = New-Object System.Windows.Forms.ListBox
$lbHosts.Location     = "12,45"
$lbHosts.Size         = New-Object System.Drawing.Size(388, 140)

$btnRemoveHost        = New-Object System.Windows.Forms.Button
$btnRemoveHost.Text   = "Remove selected"
$btnRemoveHost.Location= "12,190"
$btnRemoveHost.Size   = New-Object System.Drawing.Size(130,28)

# Interval & timeout
$lblInterval          = New-Object System.Windows.Forms.Label
$lblInterval.Text     = "Interval (sec):"
$lblInterval.Location = "420,15"
$lblInterval.AutoSize = $true

$nudInterval          = New-Object System.Windows.Forms.NumericUpDown
$nudInterval.Location = "510,12"
$nudInterval.Minimum  = 1
$nudInterval.Maximum  = 3600
$nudInterval.Value    = 5

$lblTimeout           = New-Object System.Windows.Forms.Label
$lblTimeout.Text      = "Timeout (ms):"
$lblTimeout.Location  = "600,15"
$lblTimeout.AutoSize  = $true

$nudTimeout           = New-Object System.Windows.Forms.NumericUpDown
$nudTimeout.Location  = "690,12"
$nudTimeout.Minimum   = 100
$nudTimeout.Maximum   = 10000
$nudTimeout.Increment = 100
$nudTimeout.Value     = 1000

# Controls: start/stop
$btnStart             = New-Object System.Windows.Forms.Button
$btnStart.Text        = "Start"
$btnStart.Location    = "780,10"
$btnStart.Size        = New-Object System.Drawing.Size(60,28)

$btnStop              = New-Object System.Windows.Forms.Button
$btnStop.Text         = "Stop"
$btnStop.Location     = "846,10"
$btnStop.Size         = New-Object System.Drawing.Size(60,28)
$btnStop.Enabled      = $false

# Options
$cbTrayNotify         = New-Object System.Windows.Forms.CheckBox
$cbTrayNotify.Text    = "Tray notifications"
$cbTrayNotify.Location= "420,45"
$cbTrayNotify.AutoSize= $true
$cbTrayNotify.Checked = $true

$cbSound              = New-Object System.Windows.Forms.CheckBox
$cbSound.Text         = "Sound on state change"
$cbSound.Location     = "420,70"
$cbSound.AutoSize     = $true
$cbSound.Checked      = $true

$cbLogToFile          = New-Object System.Windows.Forms.CheckBox
$cbLogToFile.Text     = "Log to file"
$cbLogToFile.Location = "420,95"
$cbLogToFile.AutoSize = $true
$cbLogToFile.Checked  = $false

$txtLogFile           = New-Object System.Windows.Forms.TextBox
$txtLogFile.Location  = "510,93"
$txtLogFile.Size      = New-Object System.Drawing.Size(315, 24)
$txtLogFile.Enabled   = $false

$btnBrowseLog         = New-Object System.Windows.Forms.Button
$btnBrowseLog.Text    = "Browse..."
$btnBrowseLog.Location= "830,92"
$btnBrowseLog.Size    = New-Object System.Drawing.Size(76,26)
$btnBrowseLog.Enabled = $false

# Log view
$lvLog                = New-Object System.Windows.Forms.ListView
$lvLog.Location       = "12,230"
$lvLog.Size           = New-Object System.Drawing.Size(894, 330)
$lvLog.View           = [System.Windows.Forms.View]::Details
$lvLog.FullRowSelect  = $true
$lvLog.GridLines      = $true
$lvLog.HideSelection  = $false

New-ListViewColumn -ListView $lvLog -Text "Timestamp"  -Width 170
New-ListViewColumn -ListView $lvLog -Text "Host"       -Width 240
New-ListViewColumn -ListView $lvLog -Text "Latency(ms)"-Width 100
New-ListViewColumn -ListView $lvLog -Text "Status"     -Width 90
New-ListViewColumn -ListView $lvLog -Text "Message"    -Width 280

# Status strip
$statusStrip          = New-Object System.Windows.Forms.StatusStrip
$sslStatus            = New-Object System.Windows.Forms.ToolStripStatusLabel
$sslStatus.Text       = "Idle"
$statusStrip.Items.Add($sslStatus) | Out-Null

# Notify icon
$notifyIcon                   = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon              = [System.Drawing.SystemIcons]::Information
$notifyIcon.Text              = "Network Watchdog"
$notifyIcon.Visible           = $true
$notifyIcon.BalloonTipTitle   = "Network Watchdog"

# Timer
$timer                = New-Object System.Windows.Forms.Timer
$timer.Interval       = [int]$nudInterval.Value * 1000

# Shared state
$lastStatus = @{}   # host -> $true/$false
$polling    = $false

#-------------------------
# Events
#-------------------------
$btnAddHost.Add_Click({
    $host = $txtHost.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($host)) { return }
    if (-not $lbHosts.Items.Contains($host)) {
        [void]$lbHosts.Items.Add($host)
        $txtHost.Clear()
    }
})

$btnRemoveHost.Add_Click({
    while ($lbHosts.SelectedIndices.Count -gt 0) {
        $lbHosts.Items.RemoveAt($lbHosts.SelectedIndices[0])
    }
})

$cbLogToFile.Add_CheckedChanged({
    $txtLogFile.Enabled = $cbLogToFile.Checked
    $btnBrowseLog.Enabled = $cbLogToFile.Checked
    if ($cbLogToFile.Checked -and [string]::IsNullOrWhiteSpace($txtLogFile.Text)) {
        Pick-LogFile
    }
})

$btnBrowseLog.Add_Click({ Pick-LogFile })

$nudInterval.Add_ValueChanged({
    $timer.Interval = [int]$nudInterval.Value * 1000
})

$btnStart.Add_Click({
    if ($lbHosts.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Add at least one host.", "Network Watchdog", "OK", "Warning") | Out-Null
        return
    }
    $btnStart.Enabled = $false
    $btnStop.Enabled  = $true
    $txtHost.Enabled  = $false
    $btnAddHost.Enabled = $false
    $btnRemoveHost.Enabled = $false
    $nudInterval.Enabled = $false
    $nudTimeout.Enabled  = $false
    $cbLogToFile.Enabled = -not $cbLogToFile.Checked # lock if enabled with file chosen
    $btnBrowseLog.Enabled = $cbLogToFile.Checked -and -not [string]::IsNullOrWhiteSpace($txtLogFile.Text) ? $false : $btnBrowseLog.Enabled
    $sslStatus.Text = "Monitoring..."
    $polling = $true
    $timer.Start()
})

$btnStop.Add_Click({
    $timer.Stop()
    $polling = $false
    $btnStart.Enabled = $true
    $btnStop.Enabled  = $false
    $txtHost.Enabled  = $true
    $btnAddHost.Enabled = $true
    $btnRemoveHost.Enabled = $true
    $nudInterval.Enabled = $true
    $nudTimeout.Enabled  = $true
    $cbLogToFile.Enabled = $true
    $btnBrowseLog.Enabled = $cbLogToFile.Checked
    $sslStatus.Text = "Stopped"
})

$timer.Add_Tick({
    if (-not $polling) { return }
    $sslStatus.Text = "Polling..."
    foreach ($host in $lbHosts.Items) {
        $res = Test-Host -Host $host -TimeoutMs ([int]$nudTimeout.Value)
        $ts  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $latencyText = if ($res.Success) { "{0}" -f $res.Roundtrip } else { "" }
        $statusText  = if ($res.Success) { "UP" } else { "DOWN" }
        Add-LogRow -Timestamp $ts -Host $host -LatencyText $latencyText -StatusText $statusText -Message $res.Message

        # State change?
        $prev = $null
        if ($lastStatus.ContainsKey($host)) { $prev = $lastStatus[$host] }
        if ($prev -ne $res.Success) {
            $lastStatus[$host] = $res.Success
            if ($cbSound.Checked) {
                if ($res.Success) { [System.Media.SystemSounds]::Asterisk.Play() } else { [System.Media.SystemSounds]::Exclamation.Play() }
            }
            if ($res.Success) {
                Show-Notify -Title "Host UP" -Text "$host is reachable ($($res.Roundtrip) ms)" -Icon ([System.Windows.Forms.ToolTipIcon]::Info)
            } else {
                Show-Notify -Title "Host DOWN" -Text "$host is not reachable ($($res.Message))" -Icon ([System.Windows.Forms.ToolTipIcon]::Error)
            }
        } else {
            $lastStatus[$host] = $res.Success
        }
    }
    $sslStatus.Text = "Monitoring..."
})

$form.Add_FormClosing({
    $timer.Stop()
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
})

#-------------------------
# Add controls and show
#-------------------------
$form.Controls.AddRange(@(
    $lblHost, $txtHost, $btnAddHost, $lbHosts, $btnRemoveHost,
    $lblInterval, $nudInterval, $lblTimeout, $nudTimeout,
    $btnStart, $btnStop,
    $cbTrayNotify, $cbSound, $cbLogToFile, $txtLogFile, $btnBrowseLog,
    $lvLog, $statusStrip
))
$form.Topmost = $false

# Expose globals used in helpers
$global:lvLog        = $lvLog
$global:cbLogToFile  = $cbLogToFile
$global:txtLogFile   = $txtLogFile
$global:notifyIcon   = $notifyIcon
$global:cbTrayNotify = $cbTrayNotify

# Default example hosts (you can remove)
[void]$lbHosts.Items.Add("8.8.8.8")
[void]$lbHosts.Items.Add("1.1.1.1")
[void]$lbHosts.Items.Add("localhost")

# Run
# Ensure Single Threaded Apartment for WinForms reliability
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    [System.Windows.Forms.MessageBox]::Show("Please run this script with -STA (Single Threaded Apartment).`nExample:`n  powershell.exe -STA -File .\NetworkWatchdog.ps1","Network Watchdog","OK","Warning") | Out-Null
}
[void]$form.ShowDialog()
