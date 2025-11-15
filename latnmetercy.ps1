<# 
WiFi Latency Meter with AI Insights (Single .ps1)
- WinForms GUI with start/stop controls
- Measures latency, jitter, packet loss via ICMP
- Auto-detects Wi-Fi adapter & default gateway
- Real-time metrics and rolling averages
- Optional AI analysis via REST (config below)
- Admin-safe, cleans up timers and threads on exit
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.NetworkInformation
Add-Type -AssemblyName System.Web

# -----------------------------
# Config: AI endpoint (optional)
# -----------------------------
$Global:AI_Enabled = $true          # Set $false to disable AI calls
$Global:AI_Endpoint = "https://example.com/ai/insights"  # Replace with your endpoint
$Global:AI_ApiKey   = "YOUR_API_KEY"                     # Replace with your secret
$Global:AI_TimeoutMs = 8000

# -----------------------------
# Globals and state
# -----------------------------
$Global:Sampling = $false
$Global:SamplingIntervalMs = 500
$Global:Window = $null
$Global:Timer = $null
$Global:PingTarget = "8.8.8.8"
$Global:Gateway = $null
$Global:AdapterName = $null
$Global:LatencyHistory = New-Object System.Collections.Concurrent.ConcurrentQueue[double]
$Global:MaxHistory = 200
$Global:PacketCount = 0
$Global:PacketSuccess = 0

# -----------------------------
# Helpers
# -----------------------------

function Get-ActiveWifiInfo {
    # Returns @{ Name; Gateway; IPv4 } of active Wi-Fi adapter if available
    try {
        $profiles = netsh wlan show interfaces
        $wifiConnected = $profiles -match 'State\s*:\s*connected'
        if (-not $wifiConnected) { return $null }

        # Get IPv4 and interface name via Get-NetIPInterface & Get-NetIPConfiguration if available
        $adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'Wireless|Wi-Fi' } | Select-Object -First 1
        if (-not $adapter) { 
            $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'Wireless|Wi-Fi' } | Select-Object -First 1
        }
        $ipcfg = Get-NetIPConfiguration -InterfaceIndex $adapter.IfIndex
        $gw = $ipcfg.IPv4DefaultGateway.NextHop
        return @{
            Name   = $adapter.Name
            Gateway= $gw
            IPv4   = ($ipcfg.IPv4Address.IPAddress)
        }
    } catch {
        # Fallback: parse route print for default gateway
        try {
            $routes = route print
            $defaultGwLine = ($routes | Select-String -Pattern '0\.0\.0\.0\s+0\.0\.0\.0\s+(\d{1,3}(\.\d{1,3}){3})').Matches.Value | Select-Object -First 1
            $gw = ($defaultGwLine -split '\s+') | Where-Object { $_ -match '\d{1,3}(\.\d{1,3}){3}' } | Select-Object -Last 1
            return @{ Name = "Wi-Fi"; Gateway = $gw; IPv4 = $null }
        } catch { return $null }
    }
}

function Compute-Jitter {
    param([double[]]$series)
    if (-not $series -or $series.Count -lt 2) { return [double]::NaN }
    $diffs = @()
    for ($i=1; $i -lt $series.Count; $i++) { $diffs += [math]::Abs($series[$i] - $series[$i-1]) }
    # Use mean absolute difference as jitter
    return ($diffs | Measure-Object -Average).Average
}

function Enqueue-Latency {
    param([double]$value)
    $Global:LatencyHistory.Enqueue($value)
    while ($Global:LatencyHistory.Count -gt $Global:MaxHistory) {
        [void]$Global:LatencyHistory.TryDequeue([ref]([double]0))
    }
}

function Get-LatencyStats {
    $arr = $Global:LatencyHistory.ToArray()
    if (-not $arr -or $arr.Count -eq 0) {
        return @{
            Count = 0; Avg = [double]::NaN; Min = [double]::NaN; Max = [double]::NaN; Jitter = [double]::NaN
        }
    }
    $m = ($arr | Measure-Object -Minimum -Maximum -Average)
    return @{
        Count  = $arr.Count
        Avg    = [math]::Round($m.Average,2)
        Min    = [math]::Round($m.Minimum,2)
        Max    = [math]::Round($m.Maximum,2)
        Jitter = [math]::Round((Compute-Jitter -series $arr),2)
    }
}

function Safe-Int {
    param($s)
    try { [int]$s } catch { 0 }
}

function Ping-Once {
    param([string]$host)
    $p = [System.Net.NetworkInformation.Ping]::new()
    try {
        $reply = $p.Send($host, 2000) # 2s timeout
        if ($reply.Status -eq 'Success') {
            return [double]$reply.RoundtripTime
        } else {
            return $null
        }
    } catch { return $null } finally { $p.Dispose() }
}

function Format-Ms {
    param([double]$v)
    if ($null -eq $v -or [double]::IsNaN($v)) { return "-" }
    return ("{0:N2} ms" -f $v)
}

function Format-Percent {
    param([double]$num, [double]$den)
    if ($den -le 0) { return "-" }
    $pct = 100.0 * (1.0 - ($num / $den))
    return ("{0:N2}%" -f $pct)
}

# -----------------------------
# AI Insights (optional)
# -----------------------------
function Invoke-AIInsight {
    param(
        [string]$Adapter,
        [string]$Gateway,
        [string]$Target,
        [hashtable]$Stats,    # @{ Avg; Min; Max; Jitter; Count }
        [int]$Success,
        [int]$Total
    )
    if (-not $Global:AI_Enabled) { return $null }

    $payload = [pscustomobject]@{
        adapter = $Adapter
        gateway = $Gateway
        target  = $Target
        metrics = @{
            avg_ms   = $Stats.Avg
            min_ms   = $Stats.Min
            max_ms   = $Stats.Max
            jitter_ms= $Stats.Jitter
            samples  = $Stats.Count
            packet_loss_pct = if ($Total -gt 0) { [math]::Round(100.0 * (1.0 - ($Success/$Total)),2) } else { $null }
        }
        timestamp = (Get-Date).ToString("s")
        note = "wifi_latency_meter_v1"
    }

    try {
        $json = $payload | ConvertTo-Json -Depth 5
        $client = [System.Net.Http.HttpClient]::new()
        $client.Timeout = [TimeSpan]::FromMilliseconds($Global:AI_TimeoutMs)
        $msg = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, $Global:AI_Endpoint)
        $msg.Headers.Add("Authorization", "Bearer $($Global:AI_ApiKey)")
        $msg.Content = New-Object System.Net.Http.StringContent($json, [System.Text.Encoding]::UTF8, "application/json")
        $resp = $client.SendAsync($msg).Result
        $txt = $resp.Content.ReadAsStringAsync().Result
        $client.Dispose()
        # Expecting a JSON response like { "insight": "text..." }
        try {
            $obj = $txt | ConvertFrom-Json
            return $obj.insight
        } catch {
            return $txt
        }
    } catch {
        return "AI endpoint not reachable or failed."
    }
}

# -----------------------------
# GUI
# -----------------------------
function New-Ui {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Wi-Fi Latency Meter (with AI)"
    $form.Size = New-Object System.Drawing.Size(800, 520)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $false

    # Labels
    $lblAdapter = New-Object System.Windows.Forms.Label
    $lblAdapter.Text = "Adapter:"
    $lblAdapter.Location = New-Object System.Drawing.Point(20, 20)
    $lblAdapter.AutoSize = $true

    $txtAdapter = New-Object System.Windows.Forms.TextBox
    $txtAdapter.Location = New-Object System.Drawing.Point(100, 16)
    $txtAdapter.Width = 240
    $txtAdapter.ReadOnly = $true

    $lblGateway = New-Object System.Windows.Forms.Label
    $lblGateway.Text = "Gateway:"
    $lblGateway.Location = New-Object System.Drawing.Point(360, 20)
    $lblGateway.AutoSize = $true

    $txtGateway = New-Object System.Windows.Forms.TextBox
    $txtGateway.Location = New-Object System.Drawing.Point(430, 16)
    $txtGateway.Width = 150
    $txtGateway.ReadOnly = $true

    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text = "Target:"
    $lblTarget.Location = New-Object System.Drawing.Point(20, 56)
    $lblTarget.AutoSize = $true

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(100, 52)
    $txtTarget.Width = 240
    $txtTarget.Text = $Global:PingTarget

    $lblInterval = New-Object System.Windows.Forms.Label
    $lblInterval.Text = "Interval (ms):"
    $lblInterval.Location = New-Object System.Drawing.Point(360, 56)
    $lblInterval.AutoSize = $true

    $txtInterval = New-Object System.Windows.Forms.TextBox
    $txtInterval.Location = New-Object System.Drawing.Point(450, 52)
    $txtInterval.Width = 130
    $txtInterval.Text = $Global:SamplingIntervalMs.ToString()

    # Start/Stop buttons
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Text = "Start"
    $btnStart.Location = New-Object System.Drawing.Point(600, 48)
    $btnStart.Width = 80

    $btnStop = New-Object System.Windows.Forms.Button
    $btnStop.Text = "Stop"
    $btnStop.Location = New-Object System.Drawing.Point(690, 48)
    $btnStop.Width = 80
    $btnStop.Enabled = $false

    # Metrics group
    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "Metrics"
    $grp.Location = New-Object System.Drawing.Point(20, 90)
    $grp.Size = New-Object System.Drawing.Size(400, 160)

    $lblAvg = New-Object System.Windows.Forms.Label
    $lblAvg.Text = "Avg:"
    $lblAvg.Location = New-Object System.Drawing.Point(20, 30)
    $lblAvg.AutoSize = $true
    $txtAvg = New-Object System.Windows.Forms.Label
    $txtAvg.Location = New-Object System.Drawing.Point(120, 30)
    $txtAvg.AutoSize = $true
    $txtAvg.Text = "-"

    $lblMin = New-Object System.Windows.Forms.Label
    $lblMin.Text = "Min:"
    $lblMin.Location = New-Object System.Drawing.Point(20, 60)
    $lblMin.AutoSize = $true
    $txtMin = New-Object System.Windows.Forms.Label
    $txtMin.Location = New-Object System.Drawing.Point(120, 60)
    $txtMin.AutoSize = $true
    $txtMin.Text = "-"

    $lblMax = New-Object System.Windows.Forms.Label
    $lblMax.Text = "Max:"
    $lblMax.Location = New-Object System.Drawing.Point(20, 90)
    $lblMax.AutoSize = $true
    $txtMax = New-Object System.Windows.Forms.Label
    $txtMax.Location = New-Object System.Drawing.Point(120, 90)
    $txtMax.AutoSize = $true
    $txtMax.Text = "-"

    $lblJitter = New-Object System.Windows.Forms.Label
    $lblJitter.Text = "Jitter:"
    $lblJitter.Location = New-Object System.Drawing.Point(20, 120)
    $lblJitter.AutoSize = $true
    $txtJitter = New-Object System.Windows.Forms.Label
    $txtJitter.Location = New-Object System.Drawing.Point(120, 120)
    $txtJitter.AutoSize = $true
    $txtJitter.Text = "-"

    $lblLoss = New-Object System.Windows.Forms.Label
    $lblLoss.Text = "Packet Loss:"
    $lblLoss.Location = New-Object System.Drawing.Point(220, 30)
    $lblLoss.AutoSize = $true
    $txtLoss = New-Object System.Windows.Forms.Label
    $txtLoss.Location = New-Object System.Drawing.Point(320, 30)
    $txtLoss.AutoSize = $true
    $txtLoss.Text = "-"

    $grp.Controls.AddRange(@($lblAvg,$txtAvg,$lblMin,$txtMin,$lblMax,$txtMax,$lblJitter,$txtJitter,$lblLoss,$txtLoss))

    # Live list
    $list = New-Object System.Windows.Forms.ListView
    $list.Location = New-Object System.Drawing.Point(20, 260)
    $list.Size = New-Object System.Drawing.Size(750, 160)
    $list.View = [System.Windows.Forms.View]::Details
    $list.FullRowSelect = $true
    $list.Columns.Add("Time", 140) | Out-Null
    $list.Columns.Add("Target", 160) | Out-Null
    $list.Columns.Add("Latency (ms)", 120) | Out-Null
    $list.Columns.Add("Result", 100) | Out-Null
    $list.Columns.Add("Samples", 80) | Out-Null
    $list.Columns.Add("Loss %", 80) | Out-Null

    # AI insights
    $grpAi = New-Object System.Windows.Forms.GroupBox
    $grpAi.Text = "AI Insights"
    $grpAi.Location = New-Object System.Drawing.Point(430, 90)
    $grpAi.Size = New-Object System.Drawing.Size(340, 160)

    $txtAi = New-Object System.Windows.Forms.TextBox
    $txtAi.Multiline = $true
    $txtAi.ScrollBars = "Vertical"
    $txtAi.ReadOnly = $true
    $txtAi.Location = New-Object System.Drawing.Point(10, 20)
    $txtAi.Size = New-Object System.Drawing.Size(320, 130)
    $txtAi.Text = "Insights will appear here."

    $grpAi.Controls.Add($txtAi)

    # Status bar
    $status = New-Object System.Windows.Forms.StatusStrip
    $sbLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $sbLabel.Text = "Ready."
    $status.Items.Add($sbLabel) | Out-Null

    # Form controls
    $form.Controls.AddRange(@(
        $lblAdapter,$txtAdapter,$lblGateway,$txtGateway,$lblTarget,$txtTarget,
        $lblInterval,$txtInterval,$btnStart,$btnStop,$grp,$list,$grpAi,$status
    ))

    # Populate Wi-Fi info
    $wifi = Get-ActiveWifiInfo
    if ($wifi) {
        $txtAdapter.Text = $wifi.Name
        $txtGateway.Text = $wifi.Gateway
        $Global:Gateway = $wifi.Gateway
        $Global:AdapterName = $wifi.Name
    } else {
        $txtAdapter.Text = "Unknown"
        $txtGateway.Text = "-"
        $Global:Gateway = $null
        $Global:AdapterName = "Unknown"
    }

    # Events
    $btnStart.Add_Click({
        $Global:PingTarget = $txtTarget.Text.Trim()
        $Global:SamplingIntervalMs = (Safe-Int $txtInterval.Text.Trim())
        if ($Global:SamplingIntervalMs -lt 100) { $Global:SamplingIntervalMs = 100 }

        if ([string]::IsNullOrWhiteSpace($Global:PingTarget)) {
            [System.Windows.Forms.MessageBox]::Show("Please set a valid target (e.g., 8.8.8.8 or a domain).","Target required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }

        # Reset stats
        $Global:LatencyHistory = New-Object System.Collections.Concurrent.ConcurrentQueue[double]
        $Global:PacketCount = 0
        $Global:PacketSuccess = 0
        $list.Items.Clear()
        $txtAvg.Text = "-"
        $txtMin.Text = "-"
        $txtMax.Text = "-"
        $txtJitter.Text = "-"
        $txtLoss.Text = "-"

        # Timer
        if ($Global:Timer) { $Global:Timer.Stop(); $Global:Timer.Dispose(); $Global:Timer = $null }
        $Global:Timer = New-Object System.Windows.Forms.Timer
        $Global:Timer.Interval = $Global:SamplingIntervalMs
        $Global:Timer.Add_Tick({
            if (-not $Global:Sampling) { return }
            $lat = Ping-Once -host $Global:PingTarget
            $Global:PacketCount++
            $timestamp = (Get-Date).ToString("HH:mm:ss")
            $result = "Timeout"
            if ($lat -ne $null) {
                $Global:PacketSuccess++
                Enqueue-Latency -value $lat
                $result = "Success"
            }

            $stats = Get-LatencyStats
            $lossTxt = Format-Percent -num $Global:PacketSuccess -den $Global:PacketCount

            $txtAvg.Text = (Format-Ms $stats.Avg)
            $txtMin.Text = (Format-Ms $stats.Min)
            $txtMax.Text = (Format-Ms $stats.Max)
            $txtJitter.Text = (Format-Ms $stats.Jitter)
            $txtLoss.Text = $lossTxt

            $item = New-Object System.Windows.Forms.ListViewItem($timestamp)
            $item.SubItems.Add($Global:PingTarget) | Out-Null
            $item.SubItems.Add( (if ($lat -ne $null) { "{0:N2}" -f $lat } else { "-" }) ) | Out-Null
            $item.SubItems.Add($result) | Out-Null
            $item.SubItems.Add($stats.Count.ToString()) | Out-Null
            $item.SubItems.Add($lossTxt) | Out-Null
            $list.Items.Add($item) | Out-Null
            $list.EnsureVisible($list.Items.Count-1)

            $sbLabel.Text = "Sampling: $($Global:PingTarget) every $($Global:SamplingIntervalMs) ms"

            # Periodically call AI (every ~10s)
            if ($Global:AI_Enabled -and ($Global:PacketCount % [math]::Max(1, [int](10000 / $Global:SamplingIntervalMs)) -eq 0)) {
                $insight = Invoke-AIInsight -Adapter $Global:AdapterName -Gateway $Global:Gateway -Target $Global:PingTarget -Stats $stats -Success $Global:PacketSuccess -Total $Global:PacketCount
                if ($insight) { $txtAi.Text = $insight }
            }
        })
        $Global:Sampling = $true
        $btnStart.Enabled = $false
        $btnStop.Enabled = $true
        $Global:Timer.Start()
        $sbLabel.Text = "Started."
    })

    $btnStop.Add_Click({
        $Global:Sampling = $false
        if ($Global:Timer) { $Global:Timer.Stop() }
        $btnStart.Enabled = $true
        $btnStop.Enabled = $false
        $sbLabel.Text = "Stopped."
    })

    $form.Add_FormClosing({
        $Global:Sampling = $false
        if ($Global:Timer) { try { $Global:Timer.Stop(); $Global:Timer.Dispose() } catch {} }
    })

    # Expose for handlers
    $Global:Window = @{
        Form = $form
        TxtAdapter = $txtAdapter
        TxtGateway = $txtGateway
        TxtTarget  = $txtTarget
        TxtInterval= $txtInterval
        TxtAvg     = $txtAvg
        TxtMin     = $txtMin
        TxtMax     = $txtMax
        TxtJitter  = $txtJitter
        TxtLoss    = $txtLoss
        List       = $list
        TxtAi      = $txtAi
        Status     = $sbLabel
    }

    return $form
}

# -----------------------------
# Run UI
# -----------------------------
[void][System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Ui
[void]$form.ShowDialog()
