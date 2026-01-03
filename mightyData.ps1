<# 
    WiFiMeterGUI.ps1
    Simple Wi‑Fi meter GUI using WinForms + netsh.
    - No admin required
    - Single file, no external modules
    - Polls every 1s (configurable)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#---------------------- CONFIG ----------------------#
$Global:PollIntervalMs = 1000       # Timer interval
$Global:MaxHistory     = 60         # Number of samples to keep in history

#---------------------- STATE -----------------------#
$Global:History = New-Object System.Collections.Generic.List[object]

function Get-WifiStatus {
    $output = netsh wlan show interfaces 2>$null
    if (-not $output) {
        return [pscustomobject]@{
            Time     = Get-Date
            SSID     = "<no interface>"
            BSSID    = ""
            Signal   = 0
            RSSI     = ""
            Channel  = ""
            Radio    = ""
        }
    }

    $data = @{
        Time    = Get-Date
        SSID    = ""
        BSSID   = ""
        Signal  = 0
        RSSI    = ""
        Channel = ""
        Radio   = ""
    }

    foreach ($line in $output) {
        if ($line -match "^\s*SSID\s*:\s*(.+)$" -and $data.SSID -eq "") {
            $data.SSID = $matches[1].Trim()
        }
        elseif ($line -match "^\s*BSSID\s*:\s*(.+)$") {
            $data.BSSID = $matches[1].Trim()
        }
        elseif ($line -match "^\s*Signal\s*:\s*(\d+)\s*%") {
            $data.Signal = [int]$matches[1]
        }
        elseif ($line -match "^\s*Radio type\s*:\s*(.+)$") {
            $data.Radio = $matches[1].Trim()
        }
        elseif ($line -match "^\s*Channel\s*:\s*(\d+)$") {
            $data.Channel = $matches[1].Trim()
        }
    }

    # Crude RSSI estimate from signal (approximation)
    if ($data.Signal -gt 0) {
        # Rough mapping: RSSI ≈ (Signal/2) - 100, clamped
        $rssi = [math]::Round(($data.Signal / 2) - 100)
        $data.RSSI = "$rssi dBm (approx)"
    }

    [pscustomobject]$data
}

#---------------------- GUI -------------------------#

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Wi-Fi Meter"
$form.Size          = New-Object System.Drawing.Size(700,420)
$form.StartPosition = "CenterScreen"
$form.TopMost       = $false

# Labels
$lblSSID = New-Object System.Windows.Forms.Label
$lblSSID.Location = New-Object System.Drawing.Point(10,10)
$lblSSID.Size     = New-Object System.Drawing.Size(450,20)
$lblSSID.Text     = "SSID: "

$lblBSSID = New-Object System.Windows.Forms.Label
$lblBSSID.Location = New-Object System.Drawing.Point(10,35)
$lblBSSID.Size     = New-Object System.Drawing.Size(450,20)
$lblBSSID.Text     = "BSSID: "

$lblSignal = New-Object System.Windows.Forms.Label
$lblSignal.Location = New-Object System.Drawing.Point(10,60)
$lblSignal.Size     = New-Object System.Drawing.Size(200,20)
$lblSignal.Text     = "Signal: "

$lblRSSI = New-Object System.Windows.Forms.Label
$lblRSSI.Location = New-Object System.Drawing.Point(10,85)
$lblRSSI.Size     = New-Object System.Drawing.Size(260,20)
$lblRSSI.Text     = "RSSI: "

$lblChannel = New-Object System.Windows.Forms.Label
$lblChannel.Location = New-Object System.Drawing.Point(280,85)
$lblChannel.Size     = New-Object System.Drawing.Size(200,20)
$lblChannel.Text     = "Channel: "

$lblRadio = New-Object System.Windows.Forms.Label
$lblRadio.Location = New-Object System.Drawing.Point(10,110)
$lblRadio.Size     = New-Object System.Drawing.Size(260,20)
$lblRadio.Text     = "Radio: "

# Progress bar for signal
$pbSignal = New-Object System.Windows.Forms.ProgressBar
$pbSignal.Location = New-Object System.Drawing.Point(220,60)
$pbSignal.Size     = New-Object System.Drawing.Size(200,20)
$pbSignal.Minimum  = 0
$pbSignal.Maximum  = 100

# History grid
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10,140)
$grid.Size     = New-Object System.Drawing.Size(660,210)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows    = $false
$grid.AllowUserToDeleteRows = $false
$grid.AutoSizeColumnsMode   = "Fill"
$grid.RowHeadersVisible     = $false

# Bindable list
$Global:BindingListType = ("System.ComponentModel.BindingList" -as [type]).MakeGenericType([pscustomobject])
$Global:BindingList = [Activator]::CreateInstance($BindingListType)
$grid.DataSource = $BindingList

# Start/Stop buttons
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Point(440,20)
$btnStart.Size     = New-Object System.Drawing.Size(100,30)
$btnStart.Text     = "Start"

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Location = New-Object System.Drawing.Point(550,20)
$btnStop.Size     = New-Object System.Drawing.Size(100,30)
$btnStop.Text     = "Stop"
$btnStop.Enabled  = $false

# Status label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(440,60)
$lblStatus.Size     = New-Object System.Drawing.Size(210,20)
$lblStatus.Text     = "Status: Idle"

# Timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $Global:PollIntervalMs

function Update-WifiUI {
    $status = Get-WifiStatus

    # Update labels
    $lblSSID.Text    = "SSID: "    + $status.SSID
    $lblBSSID.Text   = "BSSID: "   + $status.BSSID
    $lblSignal.Text  = "Signal: "  + $status.Signal.ToString() + " %"
    $lblRSSI.Text    = "RSSI: "    + $status.RSSI
    $lblChannel.Text = "Channel: " + $status.Channel
    $lblRadio.Text   = "Radio: "   + $status.Radio

    # Update progress bar
    $pbSignal.Value = [math]::Min([math]::Max($status.Signal,0),100)

    # Update history list
    $Global:History.Add($status)
    while ($Global:History.Count -gt $Global:MaxHistory) {
        $Global:History.RemoveAt(0)
    }

    # Rebind lightweight: clear and refill BindingList
    $BindingList.Clear()
    foreach ($item in $Global:History) {
        $BindingList.Add([pscustomobject]@{
            Time   = $item.Time.ToString("HH:mm:ss")
            SSID   = $item.SSID
            Signal = $item.Signal
            RSSI   = $item.RSSI
            Chan   = $item.Channel
            Radio  = $item.Radio
        }) | Out-Null
    }

    $lblStatus.Text = "Status: Sampling " + (Get-Date).ToString("HH:mm:ss")
}

$timer.Add_Tick({
    try {
        Update-WifiUI
    }
    catch {
        $lblStatus.Text = "Error: $($_.Exception.Message)"
    }
})

$btnStart.Add_Click({
    $timer.Start()
    $btnStart.Enabled = $false
    $btnStop.Enabled  = $true
    $lblStatus.Text   = "Status: Running..."
})

$btnStop.Add_Click({
    $timer.Stop()
    $btnStart.Enabled = $true
    $btnStop.Enabled  = $false
    $lblStatus.Text   = "Status: Stopped"
})

# Add controls
$form.Controls.AddRange(@(
    $lblSSID,
    $lblBSSID,
    $lblSignal,
    $lblRSSI,
    $lblChannel,
    $lblRadio,
    $pbSignal,
    $grid,
    $btnStart,
    $btnStop,
    $lblStatus
))

# Cleanup on close
$form.Add_FormClosing({
    $timer.Stop()
    $timer.Dispose()
})

[void]$form.ShowDialog()
