Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- Helper: Get RAM info ----------
function Get-RamInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $total = [math]::Round($os.TotalVisibleMemorySize / 1024, 1)  # MB
    $free  = [math]::Round($os.FreePhysicalMemory    / 1024, 1)  # MB
    $used  = [math]::Round($total - $free, 1)
    [pscustomobject]@{
        TotalMB = $total
        UsedMB  = $used
        FreeMB  = $free
        UsedPct = [math]::Round(($used / $total) * 100, 1)
    }
}

# ---------- Helper: Get process snapshot ----------
function Get-ProcessSnapshot {
    Get-Process | ForEach-Object {
        [pscustomobject]@{
            Name        = $_.ProcessName
            Id          = $_.Id
            RamMB       = [math]::Round($_.WorkingSet64 / 1MB, 1)
            Cpu         = $_.CPU
            Responding  = if ($_.Responding) { "Yes" } else { "No" }
            MainWindow  = $_.MainWindowTitle
        }
    } | Sort-Object -Property RamMB -Descending
}

# ---------- "AI" heuristic: suggest candidates ----------
function Invoke-AIAnalysis {
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.ListView]$ListView
    )

    if ($ListView.Items.Count -eq 0) { return }

    # Example heuristic:
    # - Mark top 10 by RAM
    # - Ignore obvious core system processes
    $corePatterns = @(
        'system', 'idle', 'services', 'lsass', 'wininit', 'winlogon',
        'csrss', 'smss', 'svchost', 'fontdrvhost', 'dwm', 'explorer'
    )

    foreach ($item in $ListView.Items) {
        $item.BackColor = [System.Drawing.Color]::White
        $item.ForeColor = [System.Drawing.Color]::Black
    }

    $maxToHighlight = [Math]::Min(10, $ListView.Items.Count)

    for ($i = 0; $i -lt $maxToHighlight; $i++) {
        $item = $ListView.Items[$i]
        $name = $item.SubItems[0].Text.ToLowerInvariant()

        $isCore = $false
        foreach ($p in $corePatterns) {
            if ($name -like "*$p*") { $isCore = $true; break }
        }

        if (-not $isCore) {
            # Mark "AI-selected" candidates with a soft color
            $item.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 230)
            $item.ForeColor = [System.Drawing.Color]::DarkRed
        }
    }
}

# ---------- GUI ----------
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "AI LLM PC RAM Cleaner"
$form.StartPosition   = "CenterScreen"
$form.Size            = New-Object System.Drawing.Size(900, 600)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false

# Top panel with RAM info
$labelRam = New-Object System.Windows.Forms.Label
$labelRam.AutoSize = $true
$labelRam.Location = New-Object System.Drawing.Point(10, 10)
$labelRam.Font     = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelRam)

# "Refresh RAM" button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text     = "Refresh RAM"
$btnRefresh.Location = New-Object System.Drawing.Point(10, 40)
$btnRefresh.Size     = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnRefresh)

# "AI Analyze" button
$btnAIAnalyze = New-Object System.Windows.Forms.Button
$btnAIAnalyze.Text     = "AI Analyze"
$btnAIAnalyze.Location = New-Object System.Drawing.Point(140, 40)
$btnAIAnalyze.Size     = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnAIAnalyze)

# "Clean Selected" button
$btnClean = New-Object System.Windows.Forms.Button
$btnClean.Text     = "Clean Selected"
$btnClean.Location = New-Object System.Drawing.Point(270, 40)
$btnClean.Size     = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($btnClean)

# Status label
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.AutoSize = $true
$labelStatus.Location = New-Object System.Drawing.Point(410, 47)
$labelStatus.Font     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$labelStatus.ForeColor = [System.Drawing.Color]::DarkSlateGray
$form.Controls.Add($labelStatus)

# ListView for processes
$listView = New-Object System.Windows.Forms.ListView
$listView.Location      = New-Object System.Drawing.Point(10, 80)
$listView.Size          = New-Object System.Drawing.Size(860, 470)
$listView.View          = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines     = $true
$listView.MultiSelect   = $true

[void]$listView.Columns.Add("Process", 200)
[void]$listView.Columns.Add("PID", 60)
[void]$listView.Columns.Add("RAM (MB)", 80)
[void]$listView.Columns.Add("CPU Time", 80)
[void]$listView.Columns.Add("Responding", 80)
[void]$listView.Columns.Add("Main Window", 340)

$form.Controls.Add($listView)

# ---------- UI update helpers ----------
function Update-RamLabel {
    param(
        [System.Windows.Forms.Label]$Label
    )
    $info = Get-RamInfo
    $Label.Text = "RAM: $($info.UsedMB) MB / $($info.TotalMB) MB  ($($info.UsedPct)%)  |  Free: $($info.FreeMB) MB"
}

function Load-ProcessList {
    param(
        [System.Windows.Forms.ListView]$ListView
    )

    $ListView.BeginUpdate()
    $ListView.Items.Clear()

    $snapshot = Get-ProcessSnapshot
    foreach ($p in $snapshot) {
        $item = New-Object System.Windows.Forms.ListViewItem($p.Name)
        [void]$item.SubItems.Add($p.Id)
        [void]$item.SubItems.Add($p.RamMB)
        [void]$item.SubItems.Add(($p.Cpu -as [string]))
        [void]$item.SubItems.Add($p.Responding)
        [void]$item.SubItems.Add($p.MainWindow)
        $ListView.Items.Add($item) | Out-Null
    }

    $ListView.EndUpdate()
}

# ---------- Event wiring ----------
$btnRefresh.Add_Click({
    Update-RamLabel -Label $labelRam
    Load-ProcessList -ListView $listView
    $labelStatus.Text = "Refreshed RAM and process list."
})

$btnAIAnalyze.Add_Click({
    Invoke-AIAnalysis -ListView $listView
    $labelStatus.Text = "AI heuristic: highlighted heavy, non-core RAM consumers."
})

$btnClean.Add_Click({
    if ($listView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Select one or more processes to attempt to close.",
            "No selection",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "The selected processes will be asked to close, and if needed, force-terminated." +
        [Environment]::NewLine +
        "This can cause unsaved work to be lost. Continue?",
        "Confirm RAM Clean",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $killed = 0
    foreach ($item in $listView.SelectedItems) {
        $pid = $item.SubItems[1].Text -as [int]
        try {
            $proc = Get-Process -Id $pid -ErrorAction Stop

            # Try graceful close if has a window
            if ($proc.MainWindowHandle -ne 0) {
                $null = $proc.CloseMainWindow()
                Start-Sleep -Milliseconds 300
                $proc.Refresh()
            }

            if (-not $proc.HasExited) {
                $proc.Kill()
            }
            $killed++
        }
        catch {
            # ignore individual failures
        }
    }

    Update-RamLabel -Label $labelRam
    Load-ProcessList -ListView $listView
    $labelStatus.Text = "AI RAM Clean: attempted to close $killed process(es)."
})

# Initial load
Update-RamLabel -Label $labelRam
Load-ProcessList -ListView $listView
$labelStatus.Text = "Ready. Use 'AI Analyze' then 'Clean Selected'."

# Run
[void][System.Windows.Forms.Application]::Run($form)
