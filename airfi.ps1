# WiFiManagerWithAI.ps1
# Windows PowerShell 5+ / PowerShell 7+ (Windows only)
# GUI Wi-Fi manager with optional LLM-based assistant (OpenAI-compatible endpoint)

[CmdletBinding()]
param()

# Ensure STA for Windows Forms
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    return
}

# Load assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Use modern TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

# --------------------------
# Helpers: Wi-Fi operations
# --------------------------

function Get-WlanInterfaces {
    $lines = (netsh wlan show interfaces) -split "`r?`n"
    $ifaces = @()
    $current = @{}
    foreach ($line in $lines) {
        if ($line -match '^\s*Name\s*:\s*(.+)$') { 
            if ($current.Count) { $ifaces += [pscustomobject]$current; $current = @{} }
            $current.Name = $Matches[1].Trim()
        } elseif ($line -match '^\s*Description\s*:\s*(.+)$') {
            $current.Description = $Matches[1].Trim()
        } elseif ($line -match '^\s*State\s*:\s*(.+)$') {
            $current.State = $Matches[1].Trim()
        } elseif ($line -match '^\s*SSID\s*:\s*(.*)$') {
            $current.SSID = $Matches[1].Trim()
        } elseif ($line -match '^\s*BSSID\s*:\s*(.*)$') {
            $current.BSSID = $Matches[1].Trim()
        } elseif ($line -match '^\s*Signal\s*:\s*(.*)$') {
            $current.Signal = $Matches[1].Trim()
        } elseif ($line -match '^\s*Channel\s*:\s*(.*)$') {
            $current.Channel = $Matches[1].Trim()
        }
    }
    if ($current.Count) { $ifaces += [pscustomobject]$current }
    return $ifaces
}

function Get-WlanProfiles {
    $lines = (netsh wlan show profiles) -split "`r?`n"
    $profiles = foreach ($l in $lines) {
        if ($l -match 'All User Profile\s*:\s*(.+)$') {
            [pscustomobject]@{ Name = $Matches[1].Trim() }
        }
    }
    $profiles
}

function Scan-WlanNetworks {
    param(
        [string]$InterfaceName
    )
    $raw = (netsh wlan show networks mode=bssid) -split "`r?`n"
    $nets = @()
    $current = $null
    $bssidCount = 0
    foreach ($line in $raw) {
        if ($line -match '^\s*SSID\s+\d+\s*:\s*(.*)$') {
            if ($null -ne $current) { $current.BSSIDCount = $bssidCount; $nets += $current }
            $ssid = $Matches[1].Trim()
            $current = [ordered]@{
                SSID = $ssid
                Security = ''
                Signal = 0
                Channel = ''
                BSSIDCount = 0
            }
            $bssidCount = 0
        } elseif ($null -ne $current -and $line -match '^\s*Authentication\s*:\s*(.*)$') {
            $current.Security = $Matches[1].Trim()
        } elseif ($null -ne $current -and $line -match '^\s*Signal\s*:\s*(\d+)%') {
            $sig = [int]$Matches[1]
            if ($sig -gt [int]$current.Signal) { $current.Signal = $sig }
        } elseif ($null -ne $current -and $line -match '^\s*Channel\s*:\s*(.*)$') {
            $current.Channel = $Matches[1].Trim()
        } elseif ($null -ne $current -and $line -match '^\s*BSSID\s+\d+\s*:\s*(.*)$') {
            $bssidCount++
        }
    }
    if ($null -ne $current) { $current.BSSIDCount = $bssidCount; $nets += [pscustomobject]$current }
    # Deduplicate SSIDs (netsh sometimes repeats)
    $nets | Group-Object SSID | ForEach-Object {
        $g = $_.Group
        $best = $g | Sort-Object Signal -Descending | Select-Object -First 1
        [pscustomobject]@{
            SSID = $_.Name
            Security = $best.Security
            Signal = $best.Signal
            Channel = $best.Channel
            BSSIDCount = ($g | Measure-Object).Count
        }
    } | Sort-Object Signal -Descending
}

function Test-ProfileExists {
    param([string]$Name)
    $exists = netsh wlan show profiles name="$Name" 2>$null
    return ($LASTEXITCODE -eq 0)
}

function New-WlanProfileXml {
    param(
        [Parameter(Mandatory)][string]$SSID,
        [Parameter()][string]$Password,
        [Parameter()][ValidateSet('WPA2PSK','OPEN')][string]$Type = $(if ($Password) { 'WPA2PSK' } else { 'OPEN' })
    )
    if ($Type -eq 'OPEN') {
@"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID><name>$SSID</name></SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>open</authentication>
                <encryption>none</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
        </security>
    </MSM>
</WLANProfile>
"@
    } else {
@"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID><name>$SSID</name></SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$Password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@
    }
}

function Connect-Wlan {
    param(
        [Parameter(Mandatory)][string]$SSID,
        [Parameter()][string]$Password
    )
    try {
        if (Test-ProfileExists -Name $SSID) {
            $null = netsh wlan connect name="$SSID" ssid="$SSID"
        } else {
            $xml = New-WlanProfileXml -SSID $SSID -Password $Password
            $tmp = [IO.Path]::GetTempFileName().Replace('.tmp','.xml')
            $xml | Out-File -FilePath $tmp -Encoding utf8 -Force
            $null = netsh wlan add profile filename="$tmp" user=current
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            $null = netsh wlan connect name="$SSID" ssid="$SSID"
        }
        Start-Sleep -Milliseconds 800
        return $true
    } catch {
        return $false
    }
}

function Disconnect-Wlan {
    try {
        $null = netsh wlan disconnect
        return $true
    } catch { return $false }
}

function Forget-WlanProfile {
    param([Parameter(Mandatory)][string]$Name)
    try {
        $null = netsh wlan delete profile name="$Name"
        return $true
    } catch { return $false }
}

function Get-AdapterName {
    # Prefer the active WLAN interface from netsh
    $ifaces = Get-WlanInterfaces
    if ($ifaces -and $ifaces[0].Name) { return $ifaces[0].Name }
    # Fallback common name
    return 'Wi-Fi'
}

function Toggle-Adapter {
    param([Parameter(Mandatory)][string]$Name,[switch]$Enable)
    try {
        if ($Enable) {
            Enable-NetAdapter -Name $Name -Confirm:$false -ErrorAction Stop | Out-Null
        } else {
            Disable-NetAdapter -Name $Name -Confirm:$false -ErrorAction Stop | Out-Null
        }
        return $true
    } catch { return $false }
}

# --------------------------
# Helpers: LLM (optional)
# --------------------------

function Invoke-LLM {
    param(
        [Parameter(Mandatory)][string]$EndpointUrl, # e.g., https://api.openai.com/v1/chat/completions
        [Parameter(Mandatory)][string]$ApiKey,
        [Parameter(Mandatory)][string]$Model,       # e.g., gpt-4o-mini
        [Parameter(Mandatory)][string]$UserPrompt,
        [Parameter()][string]$Context               # extra diagnostic context
    )
    try {
        $headers = @{
            Authorization = "Bearer $ApiKey"
            'Content-Type' = 'application/json'
        }
        $system = @"
You are a concise Wi‑Fi troubleshooting assistant. Use only the provided context when helpful. Prefer step-by-step, minimal jargon. If a fix requires admin rights, say so.

Context:
$Context
"@
        $body = @{
            model = $Model
            messages = @(
                @{ role = "system"; content = $system },
                @{ role = "user"; content = $UserPrompt }
            )
            temperature = 0.2
        } | ConvertTo-Json -Depth 6
        $resp = Invoke-RestMethod -Method Post -Uri $EndpointUrl -Headers $headers -Body $body -TimeoutSec 60
        if ($resp.choices -and $resp.choices[0].message.content) {
            return $resp.choices[0].message.content.Trim()
        } elseif ($resp.choices -and $resp.choices[0].text) {
            return $resp.choices[0].text.Trim()
        } else {
            return "No response content."
        }
    } catch {
        return "LLM error: $($_.Exception.Message)"
    }
}

# --------------------------
# UI
# --------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Wi‑Fi Manager with AI"
$form.Size = New-Object System.Drawing.Size(1080, 680)
$form.StartPosition = 'CenterScreen'

# SplitContainer: left Wi‑Fi, right AI
$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.SplitterDistance = 620
$form.Controls.Add($split)

# Left panel controls
$panelTop = New-Object System.Windows.Forms.Panel
$panelTop.Dock = 'Top'
$panelTop.Height = 90
$split.Panel1.Controls.Add($panelTop)

$lblIface = New-Object System.Windows.Forms.Label
$lblIface.Text = "Interface:"
$lblIface.Location = '10,12'
$lblIface.AutoSize = $true
$panelTop.Controls.Add($lblIface)

$cboIface = New-Object System.Windows.Forms.ComboBox
$cboIface.Location = '80,8'
$cboIface.Width = 200
$panelTop.Controls.Add($cboIface)

$btnRefreshIf = New-Object System.Windows.Forms.Button
$btnRefreshIf.Text = "Refresh"
$btnRefreshIf.Location = '290,8'
$btnRefreshIf.Width = 80
$panelTop.Controls.Add($btnRefreshIf)

$btnToggle = New-Object System.Windows.Forms.Button
$btnToggle.Text = "Disable"
$btnToggle.Location = '380,8'
$btnToggle.Width = 80
$panelTop.Controls.Add($btnToggle)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Scan"
$btnScan.Location = '470,8'
$btnScan.Width = 80
$panelTop.Controls.Add($btnScan)

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "Password:"
$lblPass.Location = '10,48'
$lblPass.AutoSize = $true
$panelTop.Controls.Add($lblPass)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = '80,44'
$txtPass.Width = 200
$txtPass.UseSystemPasswordChar = $true
$panelTop.Controls.Add($txtPass)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = '290,44'
$btnConnect.Width = 80
$panelTop.Controls.Add($btnConnect)

$btnDisconnect = New-Object System.Windows.Forms.Button
$btnDisconnect.Text = "Disconnect"
$btnDisconnect.Location = '380,44'
$btnDisconnect.Width = 80
$panelTop.Controls.Add($btnDisconnect)

$btnForget = New-Object System.Windows.Forms.Button
$btnForget.Text = "Forget"
$btnForget.Location = '470,44'
$btnForget.Width = 80
$panelTop.Controls.Add($btnForget)

# Networks list
$lv = New-Object System.Windows.Forms.ListView
$lv.View = 'Details'
$lv.FullRowSelect = $true
$lv.GridLines = $true
$lv.Dock = 'Fill'
$lv.Columns.Add("SSID", 250) | Out-Null
$lv.Columns.Add("Signal %", 80) | Out-Null
$lv.Columns.Add("Security", 130) | Out-Null
$lv.Columns.Add("Channel", 80) | Out-Null
$lv.Columns.Add("BSSIDs", 70) | Out-Null
$split.Panel1.Controls.Add($lv)
$lv.BringToFront()

# Status panel
$panelStatus = New-Object System.Windows.Forms.Panel
$panelStatus.Dock = 'Bottom'
$panelStatus.Height = 110
$split.Panel1.Controls.Add($panelStatus)

$txtStatus = New-Object System.Windows.Forms.TextBox
$txtStatus.Multiline = $true
$txtStatus.ReadOnly = $true
$txtStatus.ScrollBars = 'Vertical'
$txtStatus.Dock = 'Fill'
$panelStatus.Controls.Add($txtStatus)

# Right panel (AI)
$grpAI = New-Object System.Windows.Forms.GroupBox
$grpAI.Text = "AI Assistant (optional)"
$grpAI.Dock = 'Fill'
$split.Panel2.Controls.Add($grpAI)

$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = "Endpoint URL:"
$lblUrl.Location = '10,24'
$lblUrl.AutoSize = $true
$grpAI.Controls.Add($lblUrl)

$txtUrl = New-Object System.Windows.Forms.TextBox
$txtUrl.Location = '110,20'
$txtUrl.Width = 420
$txtUrl.Text = "https://api.openai.com/v1/chat/completions"
$grpAI.Controls.Add($txtUrl)

$lblModel = New-Object System.Windows.Forms.Label
$lblModel.Text = "Model:"
$lblModel.Location = '10,54'
$lblModel.AutoSize = $true
$grpAI.Controls.Add($lblModel)

$txtModel = New-Object System.Windows.Forms.TextBox
$txtModel.Location = '110,50'
$txtModel.Width = 200
$txtModel.Text = "gpt-4o-mini"
$grpAI.Controls.Add($txtModel)

$lblKey = New-Object System.Windows.Forms.Label
$lblKey.Text = "API Key:"
$lblKey.Location = '320,54'
$lblKey.AutoSize = $true
$grpAI.Controls.Add($lblKey)

$txtKey = New-Object System.Windows.Forms.TextBox
$txtKey.Location = '380,50'
$txtKey.Width = 150
$txtKey.UseSystemPasswordChar = $true
$grpAI.Controls.Add($txtKey)

$txtPrompt = New-Object System.Windows.Forms.TextBox
$txtPrompt.Multiline = $true
$txtPrompt.ScrollBars = 'Vertical'
$txtPrompt.Location = '10,90'
$txtPrompt.Size = New-Object System.Drawing.Size(520, 200)
$txtPrompt.Text = "Why does my signal fluctuate? Suggest steps."
$grpAI.Controls.Add($txtPrompt)

$btnAsk = New-Object System.Windows.Forms.Button
$btnAsk.Text = "Ask AI"
$btnAsk.Location = '10,300'
$btnAsk.Width = 80
$grpAI.Controls.Add($btnAsk)

$rtfAI = New-Object System.Windows.Forms.RichTextBox
$rtfAI.Location = '10,340'
$rtfAI.Size = New-Object System.Drawing.Size(520, 260)
$rtfAI.ReadOnly = $true
$grpAI.Controls.Add($rtfAI)

# --------------------------
# UI logic
# --------------------------

function Append-Status {
    param([string]$Text)
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $txtStatus.AppendText("[$timestamp] $Text`r`n")
}

function Refresh-Interfaces {
    $cboIface.Items.Clear()
    $ifs = Get-WlanInterfaces
    if (-not $ifs -or $ifs.Count -eq 0) {
        $cboIface.Items.Add('Wi-Fi') | Out-Null
        $cboIface.SelectedIndex = 0
    } else {
        foreach ($i in $ifs) { [void]$cboIface.Items.Add($i.Name) }
        $cboIface.SelectedIndex = 0
        # Toggle button text based on state
        $state = $ifs[0].State
        if ($state -match 'enabled|connected|disconnected') { $btnToggle.Text = "Disable" } else { $btnToggle.Text = "Enable" }
    }
}

function Refresh-Status {
    $iface = Get-WlanInterfaces | Select-Object -First 1
    if ($null -ne $iface) {
        $txtStatus.Lines = @(
            "Interface: $($iface.Name) ($($iface.Description))",
            "State: $($iface.State)",
            "SSID: $($iface.SSID)",
            "BSSID: $($iface.BSSID)",
            "Signal: $($iface.Signal)",
            "Channel: $($iface.Channel)"
        )
    } else {
        $txtStatus.Lines = @("No wireless interface detected.")
    }
}

function Populate-Networks {
    $lv.Items.Clear()
    $nets = Scan-WlanNetworks
    foreach ($n in $nets) {
        $item = New-Object System.Windows.Forms.ListViewItem($n.SSID)
        [void]$item.SubItems.Add([string]$n.Signal)
        [void]$item.SubItems.Add($n.Security)
        [void]$item.SubItems.Add([string]$n.Channel)
        [void]$item.SubItems.Add([string]$n.BSSIDCount)
        $lv.Items.Add($item) | Out-Null
    }
    Append-Status "Found $($nets.Count) network(s)."
}

# Events
$btnRefreshIf.Add_Click({
    Refresh-Interfaces
    Refresh-Status
})

$btnScan.Add_Click({
    Populate-Networks
    Refresh-Status
})

$lv.Add_DoubleClick({
    if ($lv.SelectedItems.Count -gt 0) {
        $ssid = $lv.SelectedItems[0].Text
        $txtPrompt.Text = "Help me connect to SSID '$ssid'. Signal fluctuates. Suggest steps."
    }
})

$btnConnect.Add_Click({
    if ($lv.SelectedItems.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Select an SSID from the list.") | Out-Null; return }
    $ssid = $lv.SelectedItems[0].Text
    $security = $lv.SelectedItems[0].SubItems[2].Text
    $pw = $txtPass.Text
    if ($security -notmatch 'Open' -and [string]::IsNullOrWhiteSpace($pw) -and -not (Test-ProfileExists -Name $ssid)) {
        [System.Windows.Forms.MessageBox]::Show("Password required for secured network (or ensure a saved profile exists).") | Out-Null
        return
    }
    Append-Status "Connecting to '$ssid'..."
    $ok = Connect-Wlan -SSID $ssid -Password $pw
    if ($ok) { Append-Status "Connected (attempted)."; Refresh-Status } else { Append-Status "Connection failed." }
})

$btnDisconnect.Add_Click({
    Append-Status "Disconnecting..."
    if (Disconnect-Wlan) { Append-Status "Disconnected."; Refresh-Status } else { Append-Status "Disconnect failed." }
})

$btnForget.Add_Click({
    $profiles = Get-WlanProfiles
    if (-not $profiles -or $profiles.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("No saved profiles found.") | Out-Null; return }
    $names = $profiles | ForEach-Object { $_.Name }
    $select = New-Object System.Windows.Forms.Form
    $select.Text = "Select profile to forget"
    $select.Size = New-Object System.Drawing.Size(380,280)
    $lb = New-Object System.Windows.Forms.ListBox
    $lb.Dock = 'Fill'
    $lb.Items.AddRange($names)
    $select.Controls.Add($lb)
    $okBtn = New-Object System.Windows.Forms.Button
    $okBtn.Text = "Forget"
    $okBtn.Dock = 'Bottom'
    $select.Controls.Add($okBtn)
    $okBtn.Add_Click({ $select.DialogResult = 'OK'; $select.Close() })
    if ($select.ShowDialog() -eq 'OK' -and $lb.SelectedItem) {
        $name = [string]$lb.SelectedItem
        Append-Status "Forgetting profile '$name'..."
        if (Forget-WlanProfile -Name $name) { Append-Status "Profile removed." } else { Append-Status "Failed to remove profile (admin rights may be required)." }
    }
})

$btnToggle.Add_Click({
    $name = Get-AdapterName
    $enable = ($btnToggle.Text -eq 'Enable')
    Append-Status ("{0} adapter '{1}'..." -f ($(if($enable){'Enabling'}else{'Disabling'})),$name)
    if (Toggle-Adapter -Name $name -Enable:$enable) {
        Append-Status "Adapter state toggled."
        Start-Sleep -Milliseconds 800
        Refresh-Interfaces
        Refresh-Status
        $btnToggle.Text = $(if ($enable) { 'Disable' } else { 'Enable' })
    } else {
        Append-Status "Adapter toggle failed (admin rights may be required)."
    }
})

$btnAsk.Add_Click({
    $url = $txtUrl.Text.Trim()
    $model = $txtModel.Text.Trim()
    $key = $txtKey.Text
    $prompt = $txtPrompt.Text
    if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($model) -or [string]::IsNullOrWhiteSpace($key)) {
        [System.Windows.Forms.MessageBox]::Show("Provide Endpoint URL, Model, and API Key.") | Out-Null
        return
    }
    # Build context from current status and latest scan
    $iface = Get-WlanInterfaces | Select-Object -First 1
    $statusBlock = if ($iface) {
@"
Interface: $($iface.Name)
State: $($iface.State)
SSID: $($iface.SSID)
BSSID: $($iface.BSSID)
Signal: $($iface.Signal)
Channel: $($iface.Channel)
"@
    } else { "No wireless interface detected." }

    $nets = Scan-WlanNetworks | Select-Object -First 12
    $netsBlock = ($nets | ForEach-Object {
        "- SSID: {0}; Signal: {1}%; Sec: {2}; Ch: {3}" -f $_.SSID, $_.Signal, $_.Security, $_.Channel
    }) -join "`r`n"

    $context = @"
Current status:
$statusBlock

Nearby networks (top 12 by signal):
$netsBlock
"@

    $rtfAI.AppendText("Asking AI...`r`n")
    $resp = Invoke-LLM -EndpointUrl $url -ApiKey $key -Model $model -UserPrompt $prompt -Context $context
    $rtfAI.AppendText("Response:`r`n$resp`r`n`r`n")
})

# Initialize
Refresh-Interfaces
Populate-Networks
Refresh-Status

[void]$form.ShowDialog()
