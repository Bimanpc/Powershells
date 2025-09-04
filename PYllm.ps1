# AI Python Compiler App - PowerShell GUI
# Save as: AiPythonCompiler.ps1
# Run: powershell -ExecutionPolicy Bypass -File .\AiPythonCompiler.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------
# App settings (persisted locally)
# ------------------------------
$AppName = "AI Python Compiler"
$ConfigDir = Join-Path $env:APPDATA "AiPythonCompiler"
$ConfigPath = Join-Path $ConfigDir "settings.json"
if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir | Out-Null }

function Load-Settings {
    if (Test-Path $ConfigPath) {
        try { return Get-Content $ConfigPath -Raw | ConvertFrom-Json } catch { }
    }
    [pscustomobject]@{
        PythonPath       = ""
        LastOpenedFile   = ""
        WindowWidth      = 1200
        WindowHeight     = 800
        ApiBase          = ""
        ApiModel         = ""
    }
}

function Save-Settings($settings) {
    ($settings | ConvertTo-Json -Depth 5) | Set-Content -Path $ConfigPath -Encoding UTF8
}

$Settings = Load-Settings

# ------------------------------
# LLM helper
# ------------------------------
function Invoke-LLM {
    param(
        [string]$Prompt,
        [string]$CodeContext = "",
        [string]$ErrorContext = ""
    )
    $apiKey  = $env:OPENAI_API_KEY
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        throw "Missing OPENAI_API_KEY environment variable."
    }

    $apiBase = if ([string]::IsNullOrWhiteSpace($Settings.ApiBase)) { $env:OPENAI_API_BASE } else { $Settings.ApiBase }
    if ([string]::IsNullOrWhiteSpace($apiBase)) { $apiBase = "https://api.openai.com/v1" }

    $model   = if ([string]::IsNullOrWhiteSpace($Settings.ApiModel)) { if ($env:OPENAI_API_MODEL) { $env:OPENAI_API_MODEL } else { "gpt-4o-mini" } } else { $Settings.ApiModel }

    $sys = @"
You are an expert Python assistant. Be concise and practical. When fixing errors, show corrected code and explain the change briefly.
"@

    $userContent = @"
User Prompt:
$Prompt

Current Python Code:
$CodeContext

Recent Error (if any):
$ErrorContext
"@

    $body = @{
        model = $model
        messages = @(
            @{ role = "system"; content = $sys },
            @{ role = "user"; content = $userContent }
        )
        temperature = 0.2
    } | ConvertTo-Json -Depth 6

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    }

    $url = "$apiBase/chat/completions"
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -TimeoutSec 120
        if ($resp.choices -and $resp.choices[0].message.content) {
            return $resp.choices[0].message.content
        } else {
            return "No response content from model."
        }
    } catch {
        return "LLM request failed: $($_.Exception.Message)"
    }
}

# ------------------------------
# Python runner
# ------------------------------
$Global:Proc = $null
$Global:LastErrorText = ""

function Get-PythonPath {
    if (-not [string]::IsNullOrWhiteSpace($Settings.PythonPath) -and (Test-Path $Settings.PythonPath)) {
        return $Settings.PythonPath
    }
    $candidate = Get-Command python -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) { return $candidate.Source }
    $candidate3 = Get-Command python3 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate3) { return $candidate3.Source }
    return ""
}

function Run-PythonCode {
    param([string]$code, [System.Windows.Forms.TextBox]$output, [System.Windows.Forms.ToolStripStatusLabel]$status)

    $python = Get-PythonPath
    if ([string]::IsNullOrWhiteSpace($python)) {
        [System.Windows.Forms.MessageBox]::Show("Python not found. Set path via Settings -> Python Path.", $AppName, 'OK', 'Warning') | Out-Null
        return
    }

    $tempDir = Join-Path $env:TEMP "AiPyCompiler"
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }
    $tempFile = Join-Path $tempDir ("run_" + [System.Guid]::NewGuid().ToString("N") + ".py")
    $code | Set-Content -Path $tempFile -Encoding UTF8

    if ($Global:Proc -and -not $Global:Proc.HasExited) {
        try { $Global:Proc.Kill() } catch { }
        $Global:Proc = $null
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $python
    $psi.Arguments = "`"$tempFile`""
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path $tempFile

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.EnableRaisingEvents = $true

    $Global:LastErrorText = ""
    $output.Clear()
    $status.Text = "Running..."

    $proc.add_OutputDataReceived({
        param($s, $e)
        if ($e.Data -ne $null) {
            $output.BeginInvoke([Action]{ $output.AppendText($e.Data + [Environment]::NewLine) }) | Out-Null
        }
    })
    $proc.add_ErrorDataReceived({
        param($s, $e)
        if ($e.Data -ne $null) {
            $Global:LastErrorText += $e.Data + [Environment]::NewLine
            $output.BeginInvoke([Action]{ 
                $output.SelectionColor = [System.Drawing.Color]::IndianRed
                $output.AppendText($e.Data + [Environment]::NewLine)
                $output.SelectionColor = $output.ForeColor
            }) | Out-Null
        }
    })
    $proc.add_Exited({
        $exitCode = $proc.ExitCode
        $output.BeginInvoke([Action]{
            $output.AppendText("`n--- Process exited with code $exitCode ---`n")
        }) | Out-Null
        $status.GetCurrentParent().Invoke([Action]{ $status.Text = "Idle" }) | Out-Null
        try { Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue } catch {}
    })

    $Global:Proc = $proc
    [void]$proc.Start()
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()
}

function Stop-PythonRun {
    if ($Global:Proc -and -not $Global:Proc.HasExited) {
        try { $Global:Proc.Kill() } catch { }
    }
}

# ------------------------------
# UI
# ------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = $AppName
$form.StartPosition = "CenterScreen"
$form.Width  = [Math]::Max(900, [int]$Settings.WindowWidth)
$form.Height = [Math]::Max(600, [int]$Settings.WindowHeight)

$menu = New-Object System.Windows.Forms.MenuStrip

$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("File")
$miNew  = New-Object System.Windows.Forms.ToolStripMenuItem("New")
$miOpen = New-Object System.Windows.Forms.ToolStripMenuItem("Open...")
$miSave = New-Object System.Windows.Forms.ToolStripMenuItem("Save")
$miSaveAs = New-Object System.Windows.Forms.ToolStripMenuItem("Save As...")
$miExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$fileMenu.DropDownItems.AddRange(@($miNew,$miOpen,$miSave,$miSaveAs,new-object System.Windows.Forms.ToolStripSeparator,$miExit))

$runMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Run")
$miRun  = New-Object System.Windows.Forms.ToolStripMenuItem("Run (F5)")
$miStop = New-Object System.Windows.Forms.ToolStripMenuItem("Stop (Shift+F5)")
$runMenu.DropDownItems.AddRange(@($miRun,$miStop))

$aiMenu = New-Object System.Windows.Forms.ToolStripMenuItem("AI")
$miAskAI = New-Object System.Windows.Forms.ToolStripMenuItem("Ask AI about code")
$miExplainErr = New-Object System.Windows.Forms.ToolStripMenuItem("Explain last error")
$aiMenu.DropDownItems.AddRange(@($miAskAI,$miExplainErr))

$settingsMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Settings")
$miPyPath = New-Object System.Windows.Forms.ToolStripMenuItem("Python Path...")
$miApiBase = New-Object System.Windows.Forms.ToolStripMenuItem("API Base URL...")
$miApiModel = New-Object System.Windows.Forms.ToolStripMenuItem("API Model...")
$settingsMenu.DropDownItems.AddRange(@($miPyPath,$miApiBase,$miApiModel))

$menu.Items.AddRange(@($fileMenu,$runMenu,$aiMenu,$settingsMenu))
$form.MainMenuStrip = $menu
$form.Controls.Add($menu)

$splitMain = New-Object System.Windows.Forms.SplitContainer
$splitMain.Dock = "Fill"
$splitMain.Orientation = "Horizontal"
$splitMain.SplitterDistance = [int]($form.Height*0.55)

# Top: code editor with toolbar
$panelTop = New-Object System.Windows.Forms.Panel
$panelTop.Dock = "Fill"

$tool = New-Object System.Windows.Forms.ToolStrip
$btnRun  = New-Object System.Windows.Forms.ToolStripButton("Run")
$btnStop = New-Object System.Windows.Forms.ToolStripButton("Stop")
$btnAsk  = New-Object System.Windows.Forms.ToolStripButton("Ask AI")
$tool.Items.AddRange(@($btnRun,$btnStop,new-object System.Windows.Forms.ToolStripSeparator,$btnAsk))
$panelTop.Controls.Add($tool)

$txtCode = New-Object System.Windows.Forms.RichTextBox
$txtCode.Font = New-Object System.Drawing.Font("Consolas", 11)
$txtCode.Dock = "Fill"
$txtCode.AcceptsTab = $true
$txtCode.WordWrap = $false

$panelTop.Controls.Add($txtCode)
$tool.BringToFront()

# Bottom: left output, right AI
$splitBottom = New-Object System.Windows.Forms.SplitContainer
$splitBottom.Dock = "Fill"
$splitBottom.Orientation = "Vertical"
$splitBottom.SplitterDistance = [int]($form.Width*0.55)

# Output panel
$grpOut = New-Object System.Windows.Forms.GroupBox
$grpOut.Text = "Output"
$grpOut.Dock = "Fill"

$txtOut = New-Object System.Windows.Forms.RichTextBox
$txtOut.ReadOnly = $true
$txtOut.Dock = "Fill"
$txtOut.Font = New-Object System.Drawing.Font("Consolas", 10)
$txtOut.BackColor = [System.Drawing.Color]::FromArgb(249,249,249)
$grpOut.Controls.Add($txtOut)

# AI panel
$grpAI = New-Object System.Windows.Forms.GroupBox
$grpAI.Text = "AI Assistant"
$grpAI.Dock = "Fill"

$panelAI = New-Object System.Windows.Forms.Panel
$panelAI.Dock = "Fill"

$txtPrompt = New-Object System.Windows.Forms.TextBox
$txtPrompt.Multiline = $true
$txtPrompt.Dock = "Top"
$txtPrompt.Height = 90
$txtPrompt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtPrompt.Text = "Explain what this code does and suggest improvements."

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "Ask AI"
$btnSend.Dock = "Top"
$btnSend.Height = 32

$txtAI = New-Object System.Windows.Forms.RichTextBox
$txtAI.ReadOnly = $true
$txtAI.Dock = "Fill"
$txtAI.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtAI.BackColor = [System.Drawing.Color]::White

$panelAI.Controls.Add($txtAI)
$panelAI.Controls.Add($btnSend)
$panelAI.Controls.Add($txtPrompt)
$grpAI.Controls.Add($panelAI)

$splitBottom.Panel1.Controls.Add($grpOut)
$splitBottom.Panel2.Controls.Add($grpAI)

$splitMain.Panel1.Controls.Add($panelTop)
$splitMain.Panel2.Controls.Add($splitBottom)
$form.Controls.Add($splitMain)

# Status bar
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Idle"
$statusStrip.Items.Add($statusLabel)
$form.Controls.Add($statusStrip)
$statusStrip.BringToFront()

# ------------------------------
# File ops
# ------------------------------
$CurrentFile = if (Test-Path $Settings.LastOpenedFile) { $Settings.LastOpenedFile } else { "" }

function Load-FromFile([string]$path) {
    $txtCode.Text = Get-Content -Raw -Path $path
    $CurrentFile = $path
    $form.Text = "$AppName - $([IO.Path]::GetFileName($path))"
    $Settings.LastOpenedFile = $path
    Save-Settings $Settings
}

function Save-ToFile([string]$path) {
    $txtCode.Text | Set-Content -Path $path -Encoding UTF8
    $CurrentFile = $path
    $form.Text = "$AppName - $([IO.Path]::GetFileName($path))"
    $Settings.LastOpenedFile = $path
    Save-Settings $Settings
}

$miNew.Add_Click({
    $txtCode.Clear()
    $CurrentFile = ""
    $form.Text = $AppName
})
$miOpen.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Python (*.py)|*.py|All files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Load-FromFile $ofd.FileName
    }
})
$miSave.Add_Click({
    if ([string]::IsNullOrWhiteSpace($CurrentFile)) {
        $miSaveAs.PerformClick()
    } else {
        Save-ToFile $CurrentFile
    }
})
$miSaveAs.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "Python (*.py)|*.py|All files (*.*)|*.*"
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Save-ToFile $sfd.FileName
    }
})
$miExit.Add_Click({ $form.Close() })

# ------------------------------
# Settings handlers
# ------------------------------
$miPyPath.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "python.exe|python.exe|All files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $Settings.PythonPath = $ofd.FileName
        Save-Settings $Settings
    }
})

function Prompt-Text([string]$title, [string]$label, [string]$value) {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = $title
    $dlg.StartPosition = "CenterParent"
    $dlg.Width = 520; $dlg.Height = 160
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $label
    $lbl.Left = 10; $lbl.Top = 15; $lbl.Width = 480
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Left = 10; $tb.Top = 40; $tb.Width = 480
    $tb.Text = $value
    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "OK"; $ok.Left = 310; $ok.Top = 70; $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = "Cancel"; $cancel.Left = 395; $cancel.Top = 70; $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dlg.AcceptButton = $ok; $dlg.CancelButton = $cancel
    $dlg.Controls.AddRange(@($lbl,$tb,$ok,$cancel))
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $tb.Text } else { return $null }
}

$miApiBase.Add_Click({
    $val = if ([string]::IsNullOrWhiteSpace($Settings.ApiBase)) { $env:OPENAI_API_BASE } else { $Settings.ApiBase }
    $res = Prompt-Text "API Base URL" "Example: https://api.openai.com/v1" $val
    if ($res -ne $null) {
        $Settings.ApiBase = $res
        Save-Settings $Settings
    }
})
$miApiModel.Add_Click({
    $val = if ([string]::IsNullOrWhiteSpace($Settings.ApiModel)) { if ($env:OPENAI_API_MODEL) { $env:OPENAI_API_MODEL } else { "gpt-4o-mini" } } else { $Settings.ApiModel }
    $res = Prompt-Text "API Model" "Chat model (e.g., gpt-4o-mini, gpt-4.1, llama3.1:70b, etc.)" $val
    if ($res -ne $null) {
        $Settings.ApiModel = $res
        Save-Settings $Settings
    }
})

# ------------------------------
# Actions
# ------------------------------
$runAction = {
    Run-PythonCode -code $txtCode.Text -output $txtOut -status $statusLabel
}
$stopAction = { Stop-PythonRun }

$askAIAction = {
    $statusLabel.Text = "Asking AI..."
    $txtAI.AppendText("Thinking..." + [Environment]::NewLine)
    Start-Job -ScriptBlock {
        param($p,$c,$e)
        Invoke-LLM -Prompt $p -CodeContext $c -ErrorContext $e
    } -ArgumentList $txtPrompt.Text, $txtCode.Text, $Global:LastErrorText | Out-Null

    Register-ObjectEvent -InputObject (Get-Job | Select-Object -Last 1) -EventName StateChanged -Action {
        if ($event.Sender.State -match "Completed|Failed|Stopped") {
            $res = Receive-Job -Id $event.Sender.Id -ErrorAction SilentlyContinue
            $form.BeginInvoke([Action]{
                $txtAI.AppendText(($res | Out-String) + [Environment]::NewLine)
                $statusLabel.Text = "Idle"
            }) | Out-Null
            Unregister-Event -SourceIdentifier $event.SourceIdentifier -ErrorAction SilentlyContinue
            Remove-Job -Id $event.Sender.Id -Force -ErrorAction SilentlyContinue
        }
    } | Out-Null
}

$explainErrAction = {
    if ([string]::IsNullOrWhiteSpace($Global:LastErrorText)) {
        [System.Windows.Forms.MessageBox]::Show("No recent error to explain.", $AppName, 'OK', 'Information') | Out-Null
        return
    }
    $txtPrompt.Text = "Explain this Python error and provide a fixed version of the code. Keep it concise."
    & $askAIAction
}

# Buttons and menus
$btnRun.Add_Click($runAction)
$btnStop.Add_Click($stopAction)
$btnAsk.Add_Click($askAIAction)
$btnSend.Add_Click($askAIAction)

$miRun.Add_Click($runAction)
$miStop.Add_Click($stopAction)
$miAskAI.Add_Click($askAIAction)
$miExplainErr.Add_Click($explainErrAction)

# Shortcuts
$form.Add_KeyDown({
    if ($_.KeyCode -eq "F5") { & $runAction }
    if ($_.KeyCode -eq "F5" -and $_.Shift) { & $stopAction }
})
$form.KeyPreview = $true

# Load initial file if any
if ($CurrentFile) {
    try { Load-FromFile $CurrentFile } catch { }
}

# Close/resize behavior
$form.Add_ResizeEnd({
    $Settings.WindowWidth  = $form.Width
    $Settings.WindowHeight = $form.Height
    Save-Settings $Settings
})
$form.Add_FormClosing({
    Stop-PythonRun
    $Settings.WindowWidth  = $form.Width
    $Settings.WindowHeight = $form.Height
    Save-Settings $Settings
})

# Show
[void]$form.ShowDialog()
