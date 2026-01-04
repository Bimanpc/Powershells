<#
Single-file PowerShell GUI: "Προσφέρεται από την βιβλιοθήκη stdio.h IDE"
- Simple text IDE with Open/Save, Run (PowerShell), and status bar.
- No admin requirements, pure .NET WinForms.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#========================
#  Helpers
#========================

function New-MenuItem {
    param(
        [string]$Text,
        [ScriptBlock]$OnClick
    )
    $item = New-Object System.Windows.Forms.ToolStripMenuItem
    $item.Text = $Text
    if ($OnClick) {
        $item.Add_Click($OnClick)
    }
    return $item
}

#========================
#  Main form
#========================

$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "Προσφέρεται από την βιβλιοθήκη stdio.h IDE"
$form.StartPosition   = "CenterScreen"
$form.Size            = New-Object System.Drawing.Size(1000, 650)
$form.MinimumSize     = New-Object System.Drawing.Size(800, 500)

# Icon-safe: ignore if fails
try {
    $form.Icon = [System.Drawing.SystemIcons]::Application
} catch {}

#========================
#  Menu strip
#========================

$menuStrip            = New-Object System.Windows.Forms.MenuStrip

# File menu
$fileMenu             = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text        = "&File"

$miNew   = New-MenuItem -Text "&New" -OnClick {
    $txtEditor.Clear()
    $currentFile = $null
    $statusLabel.Text = "New buffer"
}

$miOpen  = New-MenuItem -Text "&Open..." -OnClick {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "PowerShell (*.ps1)|*.ps1|All files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq "OK") {
        $script = Get-Content -LiteralPath $dlg.FileName -Raw
        $txtEditor.Text = $script
        $script:currentFile = $dlg.FileName
        $statusLabel.Text = "Opened: $($dlg.FileName)"
        $form.Text = "Προσφέρεται από την βιβλιοθήκη stdio.h IDE – $($dlg.SafeFileName)"
    }
}

$miSave  = New-MenuItem -Text "&Save" -OnClick {
    if (-not $script:currentFile) {
        $miSaveAs.PerformClick()
        return
    }
    $txtEditor.Text | Set-Content -LiteralPath $script:currentFile -Encoding UTF8
    $statusLabel.Text = "Saved: $($script:currentFile)"
}

$miSaveAs = New-MenuItem -Text "Save &As..." -OnClick {
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "PowerShell (*.ps1)|*.ps1|All files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq "OK") {
        $txtEditor.Text | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
        $script:currentFile = $dlg.FileName
        $statusLabel.Text = "Saved: $($dlg.FileName)"
        $form.Text = "Προσφέρεται από την βιβλιοθήκη stdio.h IDE – $($dlg.SafeFileName)"
    }
}

$miExit  = New-MenuItem -Text "E&xit" -OnClick {
    $form.Close()
}

$fileMenu.DropDownItems.AddRange(@(
    $miNew, $miOpen, $miSave, $miSaveAs,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $miExit
))

# Run menu
$runMenu              = New-Object System.Windows.Forms.ToolStripMenuItem
$runMenu.Text         = "&Run"

$miRunPS = New-MenuItem -Text "Run in PowerShell" -OnClick {
    $statusLabel.Text = "Running script in background PowerShell..."
    $outputBox.Clear()
    $scriptText = $txtEditor.Text

    Start-Job -ScriptBlock {
        param($code)
        try {
            $Error.Clear()
            $result = powershell -NoProfile -Command $code 2>&1
            [PSCustomObject]@{
                Output = ($result | Out-String)
            }
        } catch {
            [PSCustomObject]@{
                Output = ("ERROR: " + $_ | Out-String)
            }
        }
    } -ArgumentList $scriptText | Out-Null

    Register-ObjectEvent -InputObject ([System.Management.Automation.Job]::GetJobs()[-1]) `
        -EventName StateChanged -Action {
            if ($Event.Sender.State -eq 'Completed' -or
                $Event.Sender.State -eq 'Failed') {
                $data = Receive-Job -Job $Event.Sender -ErrorAction SilentlyContinue
                $form.Invoke([Action]{
                    $outputBox.Text = $data.Output
                    $statusLabel.Text = "Run finished (state: $($Event.Sender.State))"
                })
                Unregister-Event -SourceIdentifier $Event.SourceIdentifier -ErrorAction SilentlyContinue
                Remove-Job -Job $Event.Sender -Force -ErrorAction SilentlyContinue
            }
        } | Out-Null
}

$runMenu.DropDownItems.Add($miRunPS)

# Help menu
$helpMenu             = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text        = "&Help"

$miAbout = New-MenuItem -Text "&About..." -OnClick {
    [System.Windows.Forms.MessageBox]::Show(
        "Προσφέρεται από την βιβλιοθήκη stdio.h`n`nΑπλό PowerShell IDE για δοκιμές και scripts.",
        "About – stdio.h IDE",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

$helpMenu.DropDownItems.Add($miAbout)

$menuStrip.Items.AddRange(@($fileMenu, $runMenu, $helpMenu))
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

#========================
#  Layout: editor + output
#========================

$splitMain               = New-Object System.Windows.Forms.SplitContainer
$splitMain.Dock          = "Fill"
$splitMain.Orientation   = "Horizontal"
$splitMain.SplitterDistance = 380

# Editor
$txtEditor               = New-Object System.Windows.Forms.TextBox
$txtEditor.Multiline     = $true
$txtEditor.AcceptsTab    = $true
$txtEditor.AcceptsReturn = $true
$txtEditor.ScrollBars    = "Both"
$txtEditor.Font          = New-Object System.Drawing.Font("Consolas", 11)
$txtEditor.Dock          = "Fill"
$txtEditor.WordWrap      = $false

$splitMain.Panel1.Controls.Add($txtEditor)

# Output box
$outputBox               = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline     = $true
$outputBox.AcceptsReturn = $true
$outputBox.ReadOnly      = $true
$outputBox.ScrollBars    = "Both"
$outputBox.Font          = New-Object System.Drawing.Font("Consolas", 10)
$outputBox.Dock          = "Fill"
$outputBox.WordWrap      = $false
$outputBox.BackColor     = [System.Drawing.Color]::FromArgb(20,20,20)
$outputBox.ForeColor     = [System.Drawing.Color]::FromArgb(220,220,220)

$splitMain.Panel2.Controls.Add($outputBox)

$form.Controls.Add($splitMain)

#========================
#  Status bar
#========================

$statusStrip             = New-Object System.Windows.Forms.StatusStrip

$statusLabel             = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text        = "Προσφέρεται από την βιβλιοθήκη stdio.h – Ready"

$statusStrip.Items.Add($statusLabel)
$form.Controls.Add($statusStrip)

# Track caret position
$txtEditor.add_KeyUp({
    $index = $txtEditor.SelectionStart
    $line  = $txtEditor.GetLineFromCharIndex($index) + 1
    $col   = $index - $txtEditor.GetFirstCharIndexOfCurrentLine() + 1
    $statusLabel.Text = "Ln $line, Col $col – Προσφέρεται από την βιβλιοθήκη stdio.h"
})

#========================
#  Init
#========================

$script:currentFile = $null
[System.Windows.Forms.Application]::EnableVisualStyles()
[void]$form.ShowDialog()
