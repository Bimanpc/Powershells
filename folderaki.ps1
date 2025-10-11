# Requires -Version 5.1
# Run PowerShell in STA: powershell.exe -STA -File .\FolderIconChanger.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

function Set-FolderIcon {
    param(
        [Parameter(Mandatory)]
        [string]$FolderPath,
        [Parameter(Mandatory)]
        [string]$IconPath,
        [switch]$CopyIconIntoFolder
    )

    if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {
        throw "Folder not found: $FolderPath"
    }
    if (-not (Test-Path -LiteralPath $IconPath -PathType Leaf)) {
        throw "Icon file not found: $IconPath"
    }
    if ([System.IO.Path]::GetExtension($IconPath).ToLower() -ne ".ico") {
        throw "Icon must be a .ico file."
    }

    $desktopIni = Join-Path $FolderPath 'desktop.ini'

    # Optionally copy the icon into the target folder
    if ($CopyIconIntoFolder) {
        $destIcon = Join-Path $FolderPath ([System.IO.Path]::GetFileName($IconPath))
        Copy-Item -LiteralPath $IconPath -Destination $destIcon -Force
        $IconPath = $destIcon
    }

    # Write desktop.ini with icon configuration
    $iniContent = @(
        '[.ShellClassInfo]'
        "IconResource=$IconPath,0"
        'ConfirmFileOp=0'
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $desktopIni -Value $iniContent -Encoding ASCII

    # Make desktop.ini hidden + system
    $fileAttrs = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
    [System.IO.File]::SetAttributes($desktopIni, $fileAttrs)

    # Mark folder as customized (ReadOnly attribute is used by Explorer for customization)
    $folderInfo = New-Object System.IO.DirectoryInfo($FolderPath)
    $folderInfo.Attributes = $folderInfo.Attributes -bor [System.IO.FileAttributes]::ReadOnly

    # Notify shell to refresh
    try {
        $shellApp = New-Object -ComObject Shell.Application
        $shellApp.NameSpace($FolderPath) | Out-Null
    } catch { }

    return "Icon applied to: $FolderPath"
}

function Reset-FolderIcon {
    param(
        [Parameter(Mandatory)]
        [string]$FolderPath
    )

    if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {
        throw "Folder not found: $FolderPath"
    }

    $desktopIni = Join-Path $FolderPath 'desktop.ini'
    if (Test-Path -LiteralPath $desktopIni) {
        Remove-Item -LiteralPath $desktopIni -Force -ErrorAction SilentlyContinue
    }

    # Remove ReadOnly attribute from folder (if present)
    $folderInfo = New-Object System.IO.DirectoryInfo($FolderPath)
    $folderInfo.Attributes = $folderInfo.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)

    # Optional: also remove System attribute if someone set it (not usually necessary)
    $folderInfo.Attributes = $folderInfo.Attributes -band (-bnot [System.IO.FileAttributes]::System)

    # Shell refresh
    try {
        $shellApp = New-Object -ComObject Shell.Application
        $shellApp.NameSpace($FolderPath) | Out-Null
    } catch { }

    return "Icon reset for: $FolderPath"
}

# --- GUI ---
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "Folder Icon Changer"
$form.StartPosition   = "CenterScreen"
$form.Size            = New-Object System.Drawing.Size(560, 280)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Labels
$lblFolder   = New-Object System.Windows.Forms.Label
$lblFolder.Text      = "Target folder:"
$lblFolder.Location  = New-Object System.Drawing.Point(12, 20)
$lblFolder.AutoSize  = $true

$lblIcon     = New-Object System.Windows.Forms.Label
$lblIcon.Text        = "Icon (.ico):"
$lblIcon.Location    = New-Object System.Drawing.Point(12, 80)
$lblIcon.AutoSize    = $true

# Textboxes
$txtFolder   = New-Object System.Windows.Forms.TextBox
$txtFolder.Location   = New-Object System.Drawing.Point(110, 16)
$txtFolder.Size       = New-Object System.Drawing.Size(340, 24)

$txtIcon     = New-Object System.Windows.Forms.TextBox
$txtIcon.Location     = New-Object System.Drawing.Point(110, 76)
$txtIcon.Size         = New-Object System.Drawing.Size(340, 24)

# Buttons: Browse
$btnBrowseFolder = New-Object System.Windows.Forms.Button
$btnBrowseFolder.Text      = "Browse..."
$btnBrowseFolder.Location  = New-Object System.Drawing.Point(460, 15)
$btnBrowseFolder.Size      = New-Object System.Drawing.Size(80, 26)

$btnBrowseIcon = New-Object System.Windows.Forms.Button
$btnBrowseIcon.Text        = "Browse..."
$btnBrowseIcon.Location    = New-Object System.Drawing.Point(460, 75)
$btnBrowseIcon.Size        = New-Object System.Drawing.Size(80, 26)

# Checkbox: copy icon
$chkCopy = New-Object System.Windows.Forms.CheckBox
$chkCopy.Text       = "Copy icon into folder"
$chkCopy.Location   = New-Object System.Drawing.Point(110, 110)
$chkCopy.AutoSize   = $true
$chkCopy.Checked    = $true

# Action buttons
$btnApply  = New-Object System.Windows.Forms.Button
$btnApply.Text       = "Apply icon"
$btnApply.Location   = New-Object System.Drawing.Point(110, 150)
$btnApply.Size       = New-Object System.Drawing.Size(120, 32)

$btnReset  = New-Object System.Windows.Forms.Button
$btnReset.Text       = "Reset"
$btnReset.Location   = New-Object System.Drawing.Point(240, 150)
$btnReset.Size       = New-Object System.Drawing.Size(120, 32)

$btnClose  = New-Object System.Windows.Forms.Button
$btnClose.Text       = "Close"
$btnClose.Location   = New-Object System.Drawing.Point(370, 150)
$btnClose.Size       = New-Object System.Drawing.Size(80, 32)

# Status
$lblStatus  = New-Object System.Windows.Forms.Label
$lblStatus.Text       = ""
$lblStatus.Location   = New-Object System.Drawing.Point(12, 200)
$lblStatus.AutoSize   = $true
$lblStatus.ForeColor  = [System.Drawing.Color]::ForestGreen

# Add controls
$form.Controls.AddRange(@(
    $lblFolder, $txtFolder, $btnBrowseFolder,
    $lblIcon,   $txtIcon,   $btnBrowseIcon,
    $chkCopy,
    $btnApply, $btnReset, $btnClose,
    $lblStatus
))

# Events
$btnBrowseFolder.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "Select a folder to customize"
    $fbd.ShowNewFolderButton = $true
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtFolder.Text = $fbd.SelectedPath
    }
})

$btnBrowseIcon.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title = "Select .ico file"
    $ofd.Filter = "Icon files (*.ico)|*.ico|All files (*.*)|*.*"
    $ofd.CheckFileExists = $true
    $ofd.Multiselect = $false
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtIcon.Text = $ofd.FileName
    }
})

$btnApply.Add_Click({
    $lblStatus.ForeColor = [System.Drawing.Color]::ForestGreen
    try {
        if ([string]::IsNullOrWhiteSpace($txtFolder.Text)) { throw "Select a target folder." }
        if ([string]::IsNullOrWhiteSpace($txtIcon.Text))   { throw "Select a .ico file." }
        $msg = Set-FolderIcon -FolderPath $txtFolder.Text -IconPath $txtIcon.Text -CopyIconIntoFolder:$($chkCopy.Checked)
        $lblStatus.Text = $msg
    } catch {
        $lblStatus.ForeColor = [System.Drawing.Color]::Firebrick
        $lblStatus.Text = "Error: $($_.Exception.Message)"
    }
})

$btnReset.Add_Click({
    $lblStatus.ForeColor = [System.Drawing.Color]::ForestGreen
    try {
        if ([string]::IsNullOrWhiteSpace($txtFolder.Text)) { throw "Select a target folder to reset." }
        $msg = Reset-FolderIcon -FolderPath $txtFolder.Text
        $lblStatus.Text = $msg
    } catch {
        $lblStatus.ForeColor = [System.Drawing.Color]::Firebrick
        $lblStatus.Text = "Error: $($_.Exception.Message)"
    }
})

$btnClose.Add_Click({ $form.Close() })

# Show
$form.TopMost = $false
[void]$form.ShowDialog()
