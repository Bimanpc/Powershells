# USB-Toolbox.ps1
# Requires PowerShell 5.1+ on Windows
# -----------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-USBDrives {
    $usbDisks = Get-Disk | Where-Object BusType -eq 'USB'
    $usbDisks | ForEach-Object {
        $vol = Get-Partition -DiskNumber $_.Number -ErrorAction SilentlyContinue |
               Get-Volume -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            DiskNumber   = $_.Number
            FriendlyName = $_.FriendlyName
            SizeGB       = [math]::Round($_.Size/1GB,2)
            DriveLetter  = ($vol.DriveLetter) -join ''
            FileSystem   = ($vol.FileSystem) -join ''
            HealthStatus = $_.HealthStatus
        }
    }
}

function Format-USBDrive {
    param($driveLetter, $fileSystem, $label)
    if (-not $driveLetter) { throw "No drive selected" }
    Format-Volume -DriveLetter $driveLetter `
                  -FileSystem $fileSystem `
                  -NewFileSystemLabel $label `
                  -Confirm:$false -Force
    [System.Windows.Forms.MessageBox]::Show("Formatted $driveLetter: as $fileSystem","Done")
}

function Eject-USBDrive {
    param($driveLetter)
    if (-not $driveLetter) { throw "No drive selected" }
    # Dismount then attempt safe removal
    mountvol "$driveLetter:`\" /p | Out-Null
    [System.Windows.Forms.MessageBox]::Show("$driveLetter: has been ejected","Done")
}

function SecureWipe-USBDrive {
    param($driveLetter)
    if (-not $driveLetter) { throw "No drive selected" }
    # Zero-fill every file/folder
    Get-ChildItem "$driveLetter:`\" -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue }
    [System.Windows.Forms.MessageBox]::Show("$driveLetter: wiped clean","Done")
}

# --- Build the Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "USB Toolbox"
$form.Size = New-Object System.Drawing.Size(700,450)
$form.StartPosition = "CenterScreen"

# DataGridView to list drives
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = '10,10'; $grid.Size = '660,200'
$grid.ReadOnly = $true
$grid.SelectionMode = 'FullRowSelect'
$form.Controls.Add($grid)

# FileSystem dropdown
$lblFs = New-Object System.Windows.Forms.Label
$lblFs.Text = "FileSystem:"; $lblFs.Location='10,220'
$form.Controls.Add($lblFs)
$cbFs = New-Object System.Windows.Forms.ComboBox
$cbFs.Items.AddRange(@("NTFS","FAT32","exFAT"))
$cbFs.DropDownStyle = 'DropDownList'; $cbFs.Location='90,217'; $cbFs.Width=100
$cbFs.SelectedIndex = 0
$form.Controls.Add($cbFs)

# Label textbox
$lblLbl = New-Object System.Windows.Forms.Label
$lblLbl.Text = "Volume Label:"; $lblLbl.Location='210,220'
$form.Controls.Add($lblLbl)
$tbLabel = New-Object System.Windows.Forms.TextBox
$tbLabel.Location='300,217'; $tbLabel.Width=150
$form.Controls.Add($tbLabel)

# Buttons
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Refresh"; $btnRefresh.Location='10,260'; $btnRefresh.Width=100
$form.Controls.Add($btnRefresh)

$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = "Open Drive"; $btnOpen.Location='120,260'; $btnOpen.Width=100
$form.Controls.Add($btnOpen)

$btnFormat = New-Object System.Windows.Forms.Button
$btnFormat.Text = "Format"; $btnFormat.Location='230,260'; $btnFormat.Width=100
$form.Controls.Add($btnFormat)

$btnEject = New-Object System.Windows.Forms.Button
$btnEject.Text = "Eject"; $btnEject.Location='340,260'; $btnEject.Width=100
$form.Controls.Add($btnEject)

$btnWipe = New-Object System.Windows.Forms.Button
$btnWipe.Text = "Secure Wipe"; $btnWipe.Location='450,260'; $btnWipe.Width=100
$form.Controls.Add($btnWipe)

# Load drives into grid
function Load-Grid {
    $grid.DataSource = $null
    $grid.DataSource = Get-USBDrives
}
Load-Grid

# Event handlers
$btnRefresh.Add_Click({ Load-Grid })

$btnOpen.Add_Click({
    $sel = $grid.SelectedRows
    if ($sel.Count -gt 0) { 
        $drv = $sel[0].Cells["DriveLetter"].Value
        if ($drv) { Start-Process "$drv:`\" } else { [System.Windows.Forms.MessageBox]::Show("No drive letter!","Error") }
    }
})

$btnFormat.Add_Click({
    $sel = $grid.SelectedRows
    if ($sel.Count -gt 0) {
        $drv = $sel[0].Cells["DriveLetter"].Value
        try { Format-USBDrive -driveLetter $drv -fileSystem $cbFs.SelectedItem -label $tbLabel.Text }
        catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Error") }
        Load-Grid
    }
})

$btnEject.Add_Click({
    $sel = $grid.SelectedRows
    if ($sel.Count -gt 0) {
        $drv = $sel[0].Cells["DriveLetter"].Value
        try { Eject-USBDrive -driveLetter $drv }
        catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Error") }
        Load-Grid
    }
})

$btnWipe.Add_Click({
    $sel = $grid.SelectedRows
    if ($sel.Count -gt 0) {
        $drv = $sel[0].Cells["DriveLetter"].Value
        if ([System.Windows.Forms.MessageBox]::Show("Really wipe everything on $drv:?","Confirm",[System.Windows.Forms.MessageBoxButtons]::YesNo) -eq "Yes") {
            SecureWipe-USBDrive -driveLetter $drv 
            Load-Grid
        }
    }
})

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
