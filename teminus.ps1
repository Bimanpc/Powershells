#requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------- Globals -------------
$global:sshProc = $null
$global:outputQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$global:uiTimer = $null

function Find-SshExe {
    try {
        $p = (& where.exe ssh 2>$null | Select-Object -First 1)
        if ($p) { return $p }
    } catch {}
    $candidates = @(
        "$env:WINDIR\System32\OpenSSH\ssh.exe",
        "$env:ProgramFiles\Git\usr\bin\ssh.exe",
        "$env:ProgramFiles\PuTTY\plink.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    throw "ssh.exe not found. Install Windows OpenSSH Client (Optional Features) or add ssh to PATH."
}

function Strip-Ansi {
    param([string]$s)
    if (-not $s) { return "" }
    # Remove most ANSI escape sequences to keep the GUI clean
    return ([regex]::Replace($s, '\x1B\[[0-9;?]*[a-zA-Z]', ''))
}

# ------------- UI -------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "SSH Terminal"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(960, 620)

# Labels
$lblHost = New-Object System.Windows.Forms.Label
$lblHost.Text = "Host"
$lblHost.Location = New-Object System.Drawing.Point(12,12)
$lblHost.AutoSize = $true

$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "User"
$lblUser.Location = New-Object System.Drawing.Point(260,12)
$lblUser.AutoSize = $true

$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "Port"
$lblPort.Location = New-Object System.Drawing.Point(408,12)
$lblPort.AutoSize = $true

$lblKey = New-Object System.Windows.Forms.Label
$lblKey.Text = "Private key (.pem/.ppk)"
$lblKey.Location = New-Object System.Drawing.Point(12,44)
$lblKey.AutoSize = $true

# Inputs
$txtHost = New-Object System.Windows.Forms.TextBox
$txtHost.Location = New-Object System.Drawing.Point(54,8)
$txtHost.Size = New-Object System.Drawing.Size(200,22)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(300,8)
$txtUser.Size = New-Object System.Drawing.Size(100,22)

$txtPort = New-Object System.Windows.Forms.NumericUpDown
$txtPort.Location = New-Object System.Drawing.Point(446,8)
$txtPort.Size = New-Object System.Drawing.Size(70,22)
$txtPort.Minimum = 1
$txtPort.Maximum = 65535
$txtPort.Value = 22

$txtKey = New-Object System.Windows.Forms.TextBox
$txtKey.Location = New-Object System.Drawing.Point(12,62)
$txtKey.Size = New-Object System.Drawing.Size(700,22)

$btnBrowseKey = New-Object System.Windows.Forms.Button
$btnBrowseKey.Text = "Browse"
$btnBrowseKey.Location = New-Object System.Drawing.Point(720,60)
$btnBrowseKey.Size = New-Object System.Drawing.Size(80,26)

$chkAgent = New-Object System.Windows.Forms.CheckBox
$chkAgent.Text = "Use SSH agent (Pageant/Windows OpenSSH)"
$chkAgent.Location = New-Object System.Drawing.Point(12,90)
$chkAgent.AutoSize = $true
$chkAgent.Checked = $true

$chkStripAnsi = New-Object System.Windows.Forms.CheckBox
$chkStripAnsi.Text = "Strip ANSI color codes"
$chkStripAnsi.Location = New-Object System.Drawing.Point(320,90)
$chkStripAnsi.AutoSize = $true
$chkStripAnsi.Checked = $true

# Buttons
$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(820,8)
$btnConnect.Size = New-Object System.Drawing.Size(120,30)

$btnDisconnect = New-Object System.Windows.Forms.Button
$btnDisconnect.Text = "Disconnect"
$btnDisconnect.Location = New-Object System.Drawing.Point(820,44)
$btnDisconnect.Size = New-Object System.Drawing.Size(120,30)
$btnDisconnect.Enabled = $false

# Output terminal
$txtOutput = New-Object System.Windows.Forms.RichTextBox
$txtOutput.Location = New-Object System.Drawing.Point(12,120)
$txtOutput.Size = New-Object System.Drawing.Size(928,400)
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object System.Drawing.Font("Consolas", 10)
$txtOutput.BackColor = [System.Drawing.Color]::FromArgb(18,18,18)
$txtOutput.ForeColor = [System.Drawing.Color]::Gainsboro
$txtOutput.BorderStyle = "FixedSingle"

# Command input + send
$lblCmd = New-Object System.Windows.Forms.Label
$lblCmd.Text = "Command"
$lblCmd.Location = New-Object System.Drawing.Point(12,528)
$lblCmd.AutoSize = $true

$txtCmd = New-Object System.Windows.Forms.TextBox
$txtCmd.Location = New-Object System.Drawing.Point(80,524)
$txtCmd.Size = New-Object System.Drawing.Size(760,24)
$txtCmd.Font = New-Object System.Drawing.Font("Consolas", 10)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Send"
$btnSend.Location = New-Object System.Drawing.Point(850,522)
$btnSend.Size = New-Object System.Drawing.Size(90,28)
$btnSend.Enabled = $false

# Add controls
$form.Controls.AddRange(@(
    $lblHost,$txtHost,$lblUser,$txtUser,$lblPort,$txtPort,
    $lblKey,$txtKey,$btnBrowseKey,$chkAgent,$chkStripAnsi,
    $btnConnect,$btnDisconnect,$txtOutput,$lblCmd,$txtCmd,$btnSend
))

# ------------- Logic -------------
function Append-Output {
    param([string]$text)
    if ($chkStripAnsi.Checked) {
        $text = Strip-Ansi $text
    }
    $global:outputQueue.Enqueue($text)
}

function Pump-Output {
    while ($global:outputQueue.TryDequeue([ref]$line)) {
        $txtOutput.AppendText($line + [Environment]::NewLine)
        $txtOutput.SelectionStart = $txtOutput.TextLength
        $txtOutput.ScrollToCaret()
    }
}

function Start-SSH {
    if ($global:sshProc) { return }
    $sshPath = Find-SshExe
    $host = $txtHost.Text.Trim()
    $user = $txtUser.Text.Trim()
    $port = [int]$txtPort.Value
    if (-not $host) { [System.Windows.Forms.MessageBox]::Show("Host is required."); return }
    if (-not $user) { [System.Windows.Forms.MessageBox]::Show("User is required."); return }

    $args = @("-p", $port.ToString(), "$($user)@$($host)", "-tt")
    if ($txtKey.Text.Trim() -and -not $chkAgent.Checked) {
        # Use key file when agent is not selected
        $keyPath = $txtKey.Text.Trim()
        if (-not (Test-Path $keyPath)) { [System.Windows.Forms.MessageBox]::Show("Key file not found."); return }
        $args = @("-i", $keyPath) + $args
    }

    # If plink.exe is selected, translate arguments
    if ([System.IO.Path]::GetFileName($sshPath).ToLower() -eq "plink.exe") {
        $hostPart = "$($user)@$($host)"
        $args = @("-ssh", "-P", $port.ToString())
        if ($txtKey.Text.Trim() -and -not $chkAgent.Checked) { $args += @("-i", $txtKey.Text.Trim()) }
        $args += $hostPart
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $sshPath
    $psi.Arguments = [string]::Join(' ', ($args | ForEach-Object {
        if ($_ -match '\s' -or $_ -match '[\\"]') { '"' + ($_ -replace '"','\"') + '"' } else { $_ }
    }))
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = $true
    $psi.CreateNoWindow = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi

    $handlerOut = [System.Diagnostics.DataReceivedEventHandler]{
        param($sender,$e)
        if ($e.Data) { Append-Output $e.Data }
    }
    $handlerErr = [System.Diagnostics.DataReceivedEventHandler]{
        param($sender,$e)
        if ($e.Data) { Append-Output $e.Data }
    }

    if (-not $p.Start()) {
        [System.Windows.Forms.MessageBox]::Show("Failed to start ssh.")
        return
    }

    $p.EnableRaisingEvents = $true
    $p.add_OutputDataReceived($handlerOut)
    $p.add_ErrorDataReceived($handlerErr)
    $p.BeginOutputReadLine()
    $p.BeginErrorReadLine()

    $p.add_Exited({
        # Re-enable UI on exit
        $form.BeginInvoke([Action]{
            $btnConnect.Enabled = $true
            $btnDisconnect.Enabled = $false
            $btnSend.Enabled = $false
            Append-Output "--- Session closed ---"
            Pump-Output
        })
        $global:sshProc = $null
    })

    $global:sshProc = $p
    $btnConnect.Enabled = $false
    $btnDisconnect.Enabled = $true
    $btnSend.Enabled = $true
    Append-Output ("Connecting: " + $psi.FileName + " " + $psi.Arguments)
}

function Stop-SSH {
    if ($global:sshProc) {
        try {
            # Attempt graceful exit
            $global:sshProc.StandardInput.WriteLine("exit")
            Start-Sleep -Milliseconds 200
        } catch {}
        try {
            if (-not $global:sshProc.HasExited) { $global:sshProc.Kill() }
        } catch {}
        $global:sshProc = $null
    }
}

# Timer to pump output to UI
$global:uiTimer = New-Object System.Windows.Forms.Timer
$global:uiTimer.Interval = 100
$global:uiTimer.add_Tick({ Pump-Output })
$global:uiTimer.Start()

# ------------- Events -------------
$btnBrowseKey.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Key files|*.pem;*.ppk;*.key;*.rsa;*.ed25519|All files|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtKey.Text = $dlg.FileName
    }
})

$btnConnect.Add_Click({ Start-SSH })
$btnDisconnect.Add_Click({ Stop-SSH })

$btnSend.Add_Click({
    if (-not $global:sshProc) { return }
    $cmd = $txtCmd.Text
    if ($cmd) {
        try {
            $global:sshProc.StandardInput.WriteLine($cmd)
            Append-Output "> $cmd"
            $txtCmd.Clear()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to send command.")
        }
    }
})

$txtCmd.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") {
        $btnSend.PerformClick()
        $_.SuppressKeyPress = $true
    }
})

$form.Add_FormClosing({
    $global:uiTimer.Stop()
    Stop-SSH
})

# ------------- Start -------------
# Prefill example
$txtHost.Text = "example.com"
$txtUser.Text = "root"

[void]$form.ShowDialog()
