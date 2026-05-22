Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ================== CONFIG ==================
# Path to your GNU GRABBER executable/script
$Global:GrabberPath = "C:\Tools\gnu-grabber.exe"

# Base arguments pattern (use {URL} and {OUT} placeholders)
$Global:GrabberArgsTemplate = '--url "{URL}" --out "{OUT}"'
# ============================================

# Create form
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "GNU GRABBER GUI"
$form.Size          = New-Object System.Drawing.Size(640, 420)
$form.StartPosition = "CenterScreen"
$form.Topmost       = $false

# URL label + textbox
$lblUrl        = New-Object System.Windows.Forms.Label
$lblUrl.Text   = "URL:"
$lblUrl.AutoSize = $true
$lblUrl.Location = New-Object System.Drawing.Point(10, 15)

$txtUrl              = New-Object System.Windows.Forms.TextBox
$txtUrl.Location     = New-Object System.Drawing.Point(80, 10)
$txtUrl.Size         = New-Object System.Drawing.Size(530, 20)
$txtUrl.Anchor       = "Top,Left,Right"

# Output folder label + textbox + browse
$lblOut          = New-Object System.Windows.Forms.Label
$lblOut.Text     = "Output:"
$lblOut.AutoSize = $true
$lblOut.Location = New-Object System.Drawing.Point(10, 50)

$txtOut              = New-Object System.Windows.Forms.TextBox
$txtOut.Location     = New-Object System.Drawing.Point(80, 45)
$txtOut.Size         = New-Object System.Drawing.Size(450, 20)
$txtOut.Anchor       = "Top,Left,Right"
$txtOut.Text         = [Environment]::GetFolderPath("Desktop")

$btnBrowse              = New-Object System.Windows.Forms.Button
$btnBrowse.Text         = "..."
$btnBrowse.Location     = New-Object System.Drawing.Point(540, 43)
$btnBrowse.Size         = New-Object System.Drawing.Size(70, 24)
$btnBrowse.Anchor       = "Top,Right"

$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog

$btnBrowse.Add_Click({
    if ($folderDialog.ShowDialog() -eq "OK") {
        $txtOut.Text = $folderDialog.SelectedPath
    }
})

# Run button
$btnRun              = New-Object System.Windows.Forms.Button
$btnRun.Text         = "Grab"
$btnRun.Location     = New-Object System.Drawing.Point(10, 80)
$btnRun.Size         = New-Object System.Drawing.Size(80, 30)

# Status label
$lblStatus          = New-Object System.Windows.Forms.Label
$lblStatus.Text     = "Idle"
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object System.Drawing.Point(110, 87)

# Log textbox
$txtLog              = New-Object System.Windows.Forms.TextBox
$txtLog.Location     = New-Object System.Drawing.Point(10, 120)
$txtLog.Size         = New-Object System.Drawing.Size(600, 250)
$txtLog.Multiline    = $true
$txtLog.ScrollBars   = "Vertical"
$txtLog.ReadOnly     = $true
$txtLog.Anchor       = "Top,Bottom,Left,Right"
$txtLog.Font         = New-Object System.Drawing.Font("Consolas", 9)

function Invoke-GnuGrabber {
    param(
        [string]$Url,
        [string]$OutDir
    )

    if (-not (Test-Path $Global:GrabberPath)) {
        [System.Windows.Forms.MessageBox]::Show("Grabber not found:`n$($Global:GrabberPath)","Error","OK","Error")
        return
    }

    if (-not $Url) {
        [System.Windows.Forms.MessageBox]::Show("URL is empty.","Error","OK","Error")
        return
    }

    if (-not (Test-Path $OutDir)) {
        try {
            New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Cannot create output folder:`n$OutDir","Error","OK","Error")
            return
        }
    }

    $lblStatus.Text = "Running..."
    $btnRun.Enabled = $false

    $txtLog.AppendText("=== $(Get-Date) ===`r`n")
    $txtLog.AppendText("URL: $Url`r`n")
    $txtLog.AppendText("OUT: $OutDir`r`n")

    $args = $Global:GrabberArgsTemplate.Replace("{URL}", $Url).Replace("{OUT}", $OutDir)

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $Global:GrabberPath
    $psi.Arguments              = $args
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    # Async output handlers
    $outputHandler = [System.Diagnostics.DataReceivedEventHandler]{
        param($sender, $e)
        if ($e.Data) {
            $txtLog.Invoke([Action]{ $txtLog.AppendText($e.Data + "`r`n") })
        }
    }
    $errorHandler = [System.Diagnostics.DataReceivedEventHandler]{
        param($sender, $e)
        if ($e.Data) {
            $txtLog.Invoke([Action]{ $txtLog.AppendText("[ERR] " + $e.Data + "`r`n") })
        }
    }

    $proc.add_OutputDataReceived($outputHandler)
    $proc.add_ErrorDataReceived($errorHandler)

    [void]$proc.Start()
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()

    Start-Job -ScriptBlock {
        param($p)
        $p.WaitForExit()
        return $p.ExitCode
    } -ArgumentList $proc | Out-Null

    Register-ObjectEvent -InputObject $proc -EventName Exited -Action {
        $exitCode = $Event.Sender.ExitCode
        $form.Invoke([Action]{
            $lblStatus.Text = "Done (ExitCode=$exitCode)"
            $btnRun.Enabled = $true
            $txtLog.AppendText("=== Finished with ExitCode=$exitCode ===`r`n`r`n")
        })
    } | Out-Null
}

$btnRun.Add_Click({
    Invoke-GnuGrabber -Url $txtUrl.Text -OutDir $txtOut.Text
})

# Add controls
$form.Controls.AddRange(@(
    $lblUrl, $txtUrl,
    $lblOut, $txtOut, $btnBrowse,
    $btnRun, $lblStatus,
    $txtLog
))

[void]$form.ShowDialog()
