<# 
    AI LLM SSH Client GUI
    - Single-file .ps1
    - Requires: Posh-SSH (Install-Module Posh-SSH -Scope CurrentUser)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#-----------------------------
# Config / Extensibility Hooks
#-----------------------------

# SSH session holder
$global:SshSession = $null

function Ensure-PoshSsh {
    if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Posh-SSH module not found.`nInstall with:`nInstall-Module Posh-SSH -Scope CurrentUser",
            "Missing Dependency",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return $false
    }
    Import-Module Posh-SSH -ErrorAction SilentlyContinue | Out-Null
    return $true
}

# Stub for LLM integration – wire your HTTP/pipe/backend here
function Invoke-LLM {
    param(
        [string]$Prompt,
        [string]$Context
    )

    # TODO: Replace this stub with your real LLM call.
    # Example pattern:
    # $body = @{ prompt = $Prompt; context = $Context } | ConvertTo-Json
    # $resp = Invoke-RestMethod -Uri "http://localhost:11434/llm" -Method Post -Body $body -ContentType "application/json"
    # return $resp.answer

    return "LLM STUB RESPONSE:`r`nPrompt:`r`n$Prompt`r`n`r`nContext (truncated):`r`n" + ($Context.Substring(0, [Math]::Min(500, $Context.Length)))
}

#-----------------------------
# GUI Construction
#-----------------------------

$form                = New-Object System.Windows.Forms.Form
$form.Text           = "AI LLM SSH Client"
$form.Size           = New-Object System.Drawing.Size(1000, 650)
$form.StartPosition  = "CenterScreen"

# Host
$lblHost             = New-Object System.Windows.Forms.Label
$lblHost.Text        = "Host:"
$lblHost.Location    = New-Object System.Drawing.Point(10, 15)
$lblHost.AutoSize    = $true

$txtHost             = New-Object System.Windows.Forms.TextBox
$txtHost.Location    = New-Object System.Drawing.Point(60, 10)
$txtHost.Size        = New-Object System.Drawing.Size(180, 20)
$txtHost.Text        = "127.0.0.1"

# Port
$lblPort             = New-Object System.Windows.Forms.Label
$lblPort.Text        = "Port:"
$lblPort.Location    = New-Object System.Drawing.Point(250, 15)
$lblPort.AutoSize    = $true

$txtPort             = New-Object System.Windows.Forms.TextBox
$txtPort.Location    = New-Object System.Drawing.Point(290, 10)
$txtPort.Size        = New-Object System.Drawing.Size(60, 20)
$txtPort.Text        = "22"

# User
$lblUser             = New-Object System.Windows.Forms.Label
$lblUser.Text        = "User:"
$lblUser.Location    = New-Object System.Drawing.Point(360, 15)
$lblUser.AutoSize    = $true

$txtUser             = New-Object System.Windows.Forms.TextBox
$txtUser.Location    = New-Object System.Drawing.Point(400, 10)
$txtUser.Size        = New-Object System.Drawing.Size(120, 20)

# Password
$lblPass             = New-Object System.Windows.Forms.Label
$lblPass.Text        = "Password:"
$lblPass.Location    = New-Object System.Drawing.Point(530, 15)
$lblPass.AutoSize    = $true

$txtPass             = New-Object System.Windows.Forms.TextBox
$txtPass.Location    = New-Object System.Drawing.Point(600, 10)
$txtPass.Size        = New-Object System.Drawing.Size(150, 20)
$txtPass.UseSystemPasswordChar = $true

# Connect / Disconnect buttons
$btnConnect          = New-Object System.Windows.Forms.Button
$btnConnect.Text     = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(760, 8)
$btnConnect.Size     = New-Object System.Drawing.Size(90, 25)

$btnDisconnect          = New-Object System.Windows.Forms.Button
$btnDisconnect.Text     = "Disconnect"
$btnDisconnect.Location = New-Object System.Drawing.Point(860, 8)
$btnDisconnect.Size     = New-Object System.Drawing.Size(90, 25)
$btnDisconnect.Enabled  = $false

# Command input
$lblCmd              = New-Object System.Windows.Forms.Label
$lblCmd.Text         = "Command:"
$lblCmd.Location     = New-Object System.Drawing.Point(10, 50)
$lblCmd.AutoSize     = $true

$txtCmd              = New-Object System.Windows.Forms.TextBox
$txtCmd.Location     = New-Object System.Drawing.Point(80, 45)
$txtCmd.Size         = New-Object System.Drawing.Size(680, 20)

$btnRun              = New-Object System.Windows.Forms.Button
$btnRun.Text         = "Run"
$btnRun.Location     = New-Object System.Drawing.Point(770, 43)
$btnRun.Size         = New-Object System.Drawing.Size(80, 25)
$btnRun.Enabled      = $false

$btnExplain          = New-Object System.Windows.Forms.Button
$btnExplain.Text     = "Ask AI about output"
$btnExplain.Location = New-Object System.Drawing.Point(860, 43)
$btnExplain.Size     = New-Object System.Drawing.Size(120, 25)
$btnExplain.Enabled  = $false

# SSH Output
$lblOutput           = New-Object System.Windows.Forms.Label
$lblOutput.Text      = "SSH Output:"
$lblOutput.Location  = New-Object System.Drawing.Point(10, 80)
$lblOutput.AutoSize  = $true

$txtOutput           = New-Object System.Windows.Forms.TextBox
$txtOutput.Location  = New-Object System.Drawing.Point(10, 100)
$txtOutput.Size      = New-Object System.Drawing.Size(480, 500)
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.ReadOnly  = $true

# AI Panel
$lblAiPrompt         = New-Object System.Windows.Forms.Label
$lblAiPrompt.Text    = "AI Prompt:"
$lblAiPrompt.Location= New-Object System.Drawing.Point(500, 80)
$lblAiPrompt.AutoSize= $true

$txtAiPrompt         = New-Object System.Windows.Forms.TextBox
$txtAiPrompt.Location= New-Object System.Drawing.Point(500, 100)
$txtAiPrompt.Size    = New-Object System.Drawing.Size(460, 80)
$txtAiPrompt.Multiline = $true
$txtAiPrompt.ScrollBars = "Vertical"

$btnAskAi            = New-Object System.Windows.Forms.Button
$btnAskAi.Text       = "Ask AI (free prompt)"
$btnAskAi.Location   = New-Object System.Drawing.Point(500, 190)
$btnAskAi.Size       = New-Object System.Drawing.Size(150, 25)

$lblAiResponse       = New-Object System.Windows.Forms.Label
$lblAiResponse.Text  = "AI Response:"
$lblAiResponse.Location = New-Object System.Drawing.Point(500, 225)
$lblAiResponse.AutoSize = $true

$txtAiResponse       = New-Object System.Windows.Forms.TextBox
$txtAiResponse.Location = New-Object System.Drawing.Point(500, 245)
$txtAiResponse.Size   = New-Object System.Drawing.Size(460, 355)
$txtAiResponse.Multiline = $true
$txtAiResponse.ScrollBars = "Vertical"
$txtAiResponse.ReadOnly  = $true

# Status bar
$statusStrip         = New-Object System.Windows.Forms.StatusStrip
$statusLabel         = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text    = "Disconnected"
$statusStrip.Items.Add($statusLabel) | Out-Null

#-----------------------------
# Event Handlers
#-----------------------------

$btnConnect.Add_Click({
    if (-not (Ensure-PoshSsh)) { return }

    $host = $txtHost.Text.Trim()
    $port = [int]($txtPort.Text.Trim())
    $user = $txtUser.Text.Trim()
    $pass = $txtPass.Text

    if ([string]::IsNullOrWhiteSpace($host) -or
        [string]::IsNullOrWhiteSpace($user) -or
        [string]::IsNullOrWhiteSpace($pass)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Host, User, and Password are required.",
            "Validation",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    try {
        $secPass = ConvertTo-SecureString $pass -AsPlainText -Force
        $cred    = New-Object System.Management.Automation.PSCredential($user, $secPass)

        $statusLabel.Text = "Connecting..."
        $form.Refresh()

        if ($global:SshSession) {
            $global:SshSession | Remove-SSHSession -ErrorAction SilentlyContinue
            $global:SshSession = $null
        }

        $session = New-SSHSession -ComputerName $host -Port $port -Credential $cred -AcceptKey -ErrorAction Stop
        $global:SshSession = $session

        $statusLabel.Text = "Connected to $host:$port as $user"
        $btnConnect.Enabled = $false
        $btnDisconnect.Enabled = $true
        $btnRun.Enabled = $true
        $btnExplain.Enabled = $true
    }
    catch {
        $statusLabel.Text = "Connection failed"
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to connect:`r`n$($_.Exception.Message)",
            "SSH Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$btnDisconnect.Add_Click({
    try {
        if ($global:SshSession) {
            $global:SshSession | Remove-SSHSession -ErrorAction SilentlyContinue
            $global:SshSession = $null
        }
        $statusLabel.Text = "Disconnected"
        $btnConnect.Enabled = $true
        $btnDisconnect.Enabled = $false
        $btnRun.Enabled = $false
        $btnExplain.Enabled = $false
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error during disconnect:`r`n$($_.Exception.Message)",
            "SSH Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$btnRun.Add_Click({
    if (-not $global:SshSession) {
        [System.Windows.Forms.MessageBox]::Show(
            "Not connected.",
            "SSH",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $cmd = $txtCmd.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($cmd)) { return }

    try {
        $statusLabel.Text = "Running command..."
        $form.Refresh()

        $result = Invoke-SSHCommand -SessionId $global:SshSession.SessionId -Command $cmd -ErrorAction Stop
        $outputText = $result.Output -join "`r`n"
        if ([string]::IsNullOrWhiteSpace($outputText)) {
            $outputText = "<no output>"
        }

        $txtOutput.AppendText("`r`n> $cmd`r`n$outputText`r`n")
        $statusLabel.Text = "Command completed"
    }
    catch {
        $statusLabel.Text = "Command failed"
        [System.Windows.Forms.MessageBox]::Show(
            "Command failed:`r`n$($_.Exception.Message)",
            "SSH Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$btnExplain.Add_Click({
    $context = $txtOutput.Text
    if ([string]::IsNullOrWhiteSpace($context)) {
        [System.Windows.Forms.MessageBox]::Show(
            "No SSH output to explain.",
            "AI",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $prompt = "Explain the SSH session output, including errors, and suggest next useful commands."
    $statusLabel.Text = "Querying AI (stub)..."
    $form.Refresh()

    $resp = Invoke-LLM -Prompt $prompt -Context $context
    $txtAiResponse.Text = $resp
    $statusLabel.Text = "AI response ready (stub)"
})

$btnAskAi.Add_Click({
    $prompt = $txtAiPrompt.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Enter an AI prompt first.",
            "AI",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $context = $txtOutput.Text
    $statusLabel.Text = "Querying AI (stub)..."
    $form.Refresh()

    $resp = Invoke-LLM -Prompt $prompt -Context $context
    $txtAiResponse.Text = $resp
    $statusLabel.Text = "AI response ready (stub)"
})

$form.Add_FormClosing({
    if ($global:SshSession) {
        $global:SshSession | Remove-SSHSession -ErrorAction SilentlyContinue
        $global:SshSession = $null
    }
})

#-----------------------------
# Add Controls & Run
#-----------------------------

$form.Controls.AddRange(@(
    $lblHost, $txtHost,
    $lblPort, $txtPort,
    $lblUser, $txtUser,
    $lblPass, $txtPass,
    $btnConnect, $btnDisconnect,
    $lblCmd, $txtCmd, $btnRun, $btnExplain,
    $lblOutput, $txtOutput,
    $lblAiPrompt, $txtAiPrompt, $btnAskAi,
    $lblAiResponse, $txtAiResponse,
    $statusStrip
))

[void]$form.ShowDialog()
