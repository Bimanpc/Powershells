Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Config ---
$Global:PythonExe = "python.exe"   # Or full path if needed

# --- Form ---
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Mini Python IDE"
$form.Width         = 1000
$form.Height        = 700
$form.StartPosition = "CenterScreen"

# --- Menu strip ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip

$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("File")
$miOpen   = New-Object System.Windows.Forms.ToolStripMenuItem("Open...")
$miSave   = New-Object System.Windows.Forms.ToolStripMenuItem("Save")
$miSaveAs = New-Object System.Windows.Forms.ToolStripMenuItem("Save As...")
$fileMenu.DropDownItems.AddRange(@($miOpen, $miSave, $miSaveAs))

$runMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Run")
$miRun   = New-Object System.Windows.Forms.ToolStripMenuItem("Run Script")
$runMenu.DropDownItems.Add($miRun)

$menuStrip.Items.AddRange(@($fileMenu, $runMenu))
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

# --- Controls: editor + output + buttons ---
$editor = New-Object System.Windows.Forms.TextBox
$editor.Multiline = $true
$editor.ScrollBars = "Both"
$editor.Font = New-Object System.Drawing.Font("Consolas", 11)
$editor.AcceptsTab = $true
$editor.WordWrap = $false
$editor.Anchor = "Top,Left,Right,Bottom"
$editor.Location = New-Object System.Drawing.Point(10, 30)
$editor.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 20), 350)

$output = New-Object System.Windows.Forms.TextBox
$output.Multiline = $true
$output.ScrollBars = "Both"
$output.Font = New-Object System.Drawing.Font("Consolas", 10)
$output.ReadOnly = $true
$output.WordWrap = $false
$output.Anchor = "Left,Right,Bottom"
$output.Location = New-Object System.Drawing.Point(10, 390)
$output.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 20), 230)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run"
$btnRun.Width = 80
$btnRun.Height = 30
$btnRun.Location = New-Object System.Drawing.Point(10, 630)
$btnRun.Anchor = "Left,Bottom"

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object System.Drawing.Point(110, 636)
$lblStatus.Anchor = "Left,Bottom"
$lblStatus.Text = "Ready"

$form.Controls.AddRange(@($editor, $output, $btnRun, $lblStatus))

# --- File handling state ---
$Global:CurrentFile = $null

function Show-OpenDialog {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Python files (*.py)|*.py|All files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq "OK") {
        $Global:CurrentFile = $ofd.FileName
        $editor.Text = [System.IO.File]::ReadAllText($Global:CurrentFile)
        $form.Text = "Mini Python IDE - " + (Split-Path $Global:CurrentFile -Leaf)
    }
}

function Show-SaveDialog {
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "Python files (*.py)|*.py|All files (*.*)|*.*"
    if ($sfd.ShowDialog() -eq "OK") {
        $Global:CurrentFile = $sfd.FileName
        [System.IO.File]::WriteAllText($Global:CurrentFile, $editor.Text)
        $form.Text = "Mini Python IDE - " + (Split-Path $Global:CurrentFile -Leaf)
    }
}

function Save-CurrentFile {
    if (-not $Global:CurrentFile) {
        Show-SaveDialog
    } else {
        [System.IO.File]::WriteAllText($Global:CurrentFile, $editor.Text)
    }
}

# --- Run Python script ---
function Run-PythonScript {
    $output.Clear()
    $lblStatus.Text = "Running..."
    $form.Refresh()

    # Write to temp file if not saved
    $scriptPath = $Global:CurrentFile
    if (-not $scriptPath) {
        $temp = [System.IO.Path]::GetTempFileName()
        $scriptPath = [System.IO.Path]::ChangeExtension($temp, ".py")
        [System.IO.File]::Move($temp, $scriptPath)
        [System.IO.File]::WriteAllText($scriptPath, $editor.Text)
    } else {
        [System.IO.File]::WriteAllText($scriptPath, $editor.Text)
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Global:PythonExe
    $psi.Arguments = "`"$scriptPath`""
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $null = $proc.Start()

    $stdOut = $proc.StandardOutput.ReadToEnd()
    $stdErr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    if ($stdOut) { $output.AppendText($stdOut + [Environment]::NewLine) }
    if ($stdErr) { $output.AppendText("ERRORS:" + [Environment]::NewLine + $stdErr) }

    $lblStatus.Text = "Exit code: " + $proc.ExitCode
}

# --- Wire events ---
$btnRun.Add_Click({ Run-PythonScript })

$miRun.Add_Click({ Run-PythonScript })
$miOpen.Add_Click({ Show-OpenDialog })
$miSave.Add_Click({ Save-CurrentFile })
$miSaveAs.Add_Click({ Show-SaveDialog })

# Ctrl+S, F5 shortcuts
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($sender, $e)
    if ($e.Control -and $e.KeyCode -eq "S") {
        Save-CurrentFile()
        $e.Handled = $true
    }
    elseif ($e.KeyCode -eq "F5") {
        Run-PythonScript
        $e.Handled = $true
    }
})

# --- Resize handling (optional fine-tune) ---
$form.Add_Resize({
    $editor.Width = $form.ClientSize.Width - 20
    $output.Width = $form.ClientSize.Width - 20
})

[void]$form.ShowDialog()
