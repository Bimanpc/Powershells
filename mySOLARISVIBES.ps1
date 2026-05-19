Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- CONFIG ----------
$Global:SolarisHost   = "solaris.example.com"
$Global:SolarisUser   = "youruser"
$Global:SshExe        = "ssh"   # or full path, e.g. 'C:\Windows\System32\OpenSSH\ssh.exe'
$Global:ExtraArgs     = "-o StrictHostKeyChecking=no"
# ----------------------------

# Create form
$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "Solaris Terminal GUI"
$form.Size             = New-Object System.Drawing.Size(900,600)
$form.StartPosition    = "CenterScreen"

# Command label
$lblCmd                = New-Object System.Windows.Forms.Label
$lblCmd.Text           = "Command:"
$lblCmd.AutoSize       = $true
$lblCmd.Location       = New-Object System.Drawing.Point(10,15)
$form.Controls.Add($lblCmd)

# Command textbox
$txtCmd                = New-Object System.Windows.Forms.TextBox
$txtCmd.Location       = New-Object System.Drawing.Point(80,10)
$txtCmd.Size           = New-Object System.Drawing.Size(700,25)
$txtCmd.Anchor         = "Top,Left,Right"
$form.Controls.Add($txtCmd)

# Run button
$btnRun                = New-Object System.Windows.Forms.Button
$btnRun.Text           = "Run"
$btnRun.Location       = New-Object System.Drawing.Point(790,10)
$btnRun.Size           = New-Object System.Drawing.Size(80,25)
$btnRun.Anchor         = "Top,Right"
$form.Controls.Add($btnRun)

# Output textbox
$txtOut                = New-Object System.Windows.Forms.TextBox
$txtOut.Location       = New-Object System.Drawing.Point(10,45)
$txtOut.Size           = New-Object System.Drawing.Size(860,500)
$txtOut.Multiline      = $true
$txtOut.ScrollBars     = "Both"
$txtOut.ReadOnly       = $true
$txtOut.Font           = New-Object System.Drawing.Font("Consolas",10)
$txtOut.Anchor         = "Top,Bottom,Left,Right"
$form.Controls.Add($txtOut)

# Status bar
$statusBar             = New-Object System.Windows.Forms.StatusStrip
$statusLabel           = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text      = "Ready"
$statusBar.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusBar)

function Invoke-SolarisCommand {
    param(
        [string]$Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return
    }

    $statusLabel.Text = "Running: $Command"
    $txtOut.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Command`r`n")

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName               = $Global:SshExe
        $psi.Arguments              = "$Global:ExtraArgs $($Global:SolarisUser)@$($Global:SolarisHost) `"$Command`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute        = $false
        $psi.CreateNoWindow         = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        [void]$proc.Start()

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if ($stdout) {
            $txtOut.AppendText("$stdout`r`n")
        }
        if ($stderr) {
            $txtOut.AppendText("ERROR: $stderr`r`n")
        }
    }
    catch {
        $txtOut.AppendText("EXCEPTION: $($_.Exception.Message)`r`n")
    }
    finally {
        $statusLabel.Text = "Ready"
    }
}

# Button click
$btnRun.Add_Click({
    Invoke-SolarisCommand -Command $txtCmd.Text
})

# Enter key in command box
$txtCmd.Add_KeyDown({
    if ($_.KeyCode -eq "Enter" -and -not $_.Shift) {
        $_.SuppressKeyPress = $true
        Invoke-SolarisCommand -Command $txtCmd.Text
    }
})

# Start
[void][System.Windows.Forms.Application]::Run($form)
