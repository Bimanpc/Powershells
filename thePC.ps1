# ============================================================
#  SystemInfoView.ps1
#  Displays detailed system information in a GUI (WinForms)
#  Run with: powershell.exe -ExecutionPolicy Bypass -File .\SystemInfoView.ps1
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------- Gather system information ----------------

$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
$processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$bios = Get-CimInstance -ClassName Win32_BIOS
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
$network = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Select-Object -First 1
$videoController = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1

$uptime = (Get-Date) - $operatingSystem.LastBootUpTime

$info = [ordered]@{
    "=== GENERAL ==="                    = ""
    "Computer Name"                      = $env:COMPUTERNAME
    "Current User"                       = $env:USERNAME
    "Domain"                             = $computerSystem.Domain
    "=== OPERATING SYSTEM ==="            = ""
    "OS Name"                            = $operatingSystem.Caption
    "OS Version"                         = $operatingSystem.Version
    "OS Build"                           = $operatingSystem.BuildNumber
    "OS Architecture"                    = $operatingSystem.OSArchitecture
    "Install Date"                       = $operatingSystem.InstallDate.ToString("yyyy-MM-dd HH:mm")
    "Last Boot"                          = $operatingSystem.LastBootUpTime.ToString("yyyy-MM-dd HH:mm")
    "Uptime"                             = ("{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
    "=== HARDWARE ==="                    = ""
    "Manufacturer"                       = $computerSystem.Manufacturer
    "Model"                              = $computerSystem.Model
    "CPU"                                = $processor.Name.Trim()
    "CPU Cores"                          = "$($processor.NumberOfCores) cores / $($processor.NumberOfLogicalProcessors) threads"
    "RAM Installed"                      = "{0:N1} GB" -f ($computerSystem.TotalPhysicalMemory / 1GB)
    "RAM Free"                           = "{0:N1} GB" -f ($operatingSystem.FreePhysicalMemory / 1MB)
    "BIOS Version"                       = $bios.SMBIOSBIOSVersion
    "BIOS Release Date"                  = $bios.ReleaseDate.ToString("yyyy-MM-dd")
    "GPU"                                = $videoController.Name
    "GPU Resolution"                     = "$($videoController.CurrentHorizontalResolution) x $($videoController.CurrentVerticalResolution)"
    "=== STORAGE ==="                     = ""
}

foreach ($d in $disk) {
    $used = ($d.Size - $d.FreeSpace) / 1GB
    $info["Drive $($d.DeviceID)"] = "{0:N1} GB used / {1:N1} GB total  ({2:N0}% free)" -f $used, ($d.Size / 1GB), (($d.FreeSpace / $d.Size) * 100)
}

$info["=== NETWORK ==="] = ""
$info["IP Address"]      = ($network.IPAddress | Where-Object { $_ -match '\.' }) -join ", "
$info["Subnet Mask"]     = ($network.IPSubnet   | Where-Object { $_ -match '\.' }) -join ", "
$info["Default Gateway"] = ($network.DefaultIPGateway) -join ", "
$info["MAC Address"]     = $network.MACAddress
$info["DNS Servers"]     = ($network.DNSServerSearchOrder) -join ", "

# ---------------- Build the form ----------------

$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "System Information Viewer"
$form.Size            = New-Object System.Drawing.Size(720, 640)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false

# Header panel
$headerPanel              = New-Object System.Windows.Forms.Panel
$headerPanel.Dock         = "Top"
$headerPanel.Height       = 60
$headerPanel.BackColor    = [System.Drawing.Color]::FromArgb(109, 74, 255)
$form.Controls.Add($headerPanel)

$headerLabel             = New-Object System.Windows.Forms.Label
$headerLabel.Text        = "SYSTEM INFORMATION"
$headerLabel.ForeColor   = [System.Drawing.Color]::White
$headerLabel.Font        = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$headerLabel.AutoSize    = $true
$headerLabel.Location    = New-Object System.Drawing.Point(20, 14)
$headerPanel.Controls.Add($headerLabel)

# Info textbox (read-only, scrollable)
$infoTextBox                = New-Object System.Windows.Forms.TextBox
$infoTextBox.Multiline      = $true
$infoTextBox.ReadOnly       = $true
$infoTextBox.ScrollBars     = "Vertical"
$infoTextBox.Font           = New-Object System.Drawing.Font("Consolas", 10)
$infoTextBox.BackColor      = [System.Drawing.Color]::White
$infoTextBox.Location       = New-Object System.Drawing.Point(20, 75)
$infoTextBox.Size           = New-Object System.Drawing.Size(665, 480)

$sb = New-Object System.Text.StringBuilder
foreach ($key in $info.Keys) {
    if ($key -like "===*") {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine($key)
    }
    elseif ($info[$key] -eq "") {
        continue
    }
    else {
        [void]$sb.AppendLine(("  {0,-22}: {1}" -f $key, $info[$key]))
    }
}
$infoTextBox.Text = $sb.ToString()
$form.Controls.Add($infoTextBox)

# Buttons
$copyButton              = New-Object System.Windows.Forms.Button
$copyButton.Text         = "Copy to Clipboard"
$copyButton.Location     = New-Object System.Drawing.Point(450, 565)
$copyButton.Size         = New-Object System.Drawing.Size(140, 32)
$copyButton.Add_Click({
    Set-Clipboard -Value $infoTextBox.Text
    [System.Windows.Forms.MessageBox]::Show("Information copied to clipboard.", "Copied",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($copyButton)

$saveButton              = New-Object System.Windows.Forms.Button
$saveButton.Text         = "Save as TXT..."
$saveButton.Location     = New-Object System.Drawing.Point(300, 565)
$saveButton.Size         = New-Object System.Drawing.Size(140, 32)
$saveButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter   = "Text files (*.txt)|*.txt"
    $dlg.FileName = "SystemInfo_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    if ($dlg.ShowDialog() -eq "OK") {
        $infoTextBox.Text | Out-File -FilePath $dlg.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Saved to:`n$($dlg.FileName)", "Saved",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})
$form.Controls.Add($saveButton)

$closeButton             = New-Object System.Windows.Forms.Button
$closeButton.Text        = "Close"
$closeButton.Location    = New-Object System.Drawing.Point(160, 565)
$closeButton.Size        = New-Object System.Drawing.Size(130, 32)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# Refresh button - re-query live values
$refreshButton           = New-Object System.Windows.Forms.Button
$refreshButton.Text      = "Refresh"
$refreshButton.Location  = New-Object System.Drawing.Point(20, 565)
$refreshButton.Size      = New-Object System.Drawing.Size(130, 32)
$refreshButton.Add_Click({
    # Relaunch the script for simplicity (re-runs all CIM queries)
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $form.Close()
})
$form.Controls.Add($refreshButton)

[void]$form.ShowDialog()
$form.Dispose()
