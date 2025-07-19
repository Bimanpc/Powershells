Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Δημιουργία του παραθύρου
$form = New-Object System.Windows.Forms.Form
$form.Text = "Commodore Emulator GUI"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = "CenterScreen"

# Ετικέτα
$label = New-Object System.Windows.Forms.Label
$label.Text = "AI Commodore Emulator Control Panel"
$label.AutoSize = $true
$label.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$label.Location = New-Object System.Drawing.Point(40,20)
$form.Controls.Add($label)

# Επιλογή αρχείου ROM
$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Load ROM"
$buttonBrowse.Location = New-Object System.Drawing.Point(40,70)
$buttonBrowse.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($buttonBrowse)

$romPathBox = New-Object System.Windows.Forms.TextBox
$romPathBox.Location = New-Object System.Drawing.Point(40,110)
$romPathBox.Size = New-Object System.Drawing.Size(300,20)
$romPathBox.ReadOnly = $true
$form.Controls.Add($romPathBox)

$buttonBrowse.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "Commodore Files (*.d64;*.prg)|*.d64;*.prg|All files (*.*)|*.*"
    if ($fileDialog.ShowDialog() -eq "OK") {
        $romPathBox.Text = $fileDialog.FileName
    }
})

# Κουμπί Εκκίνησης Emulator
$buttonStart = New-Object System.Windows.Forms.Button
$buttonStart.Text = "Start Emulator"
$buttonStart.Location = New-Object System.Drawing.Point(40,150)
$buttonStart.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($buttonStart)

$buttonStart.Add_Click({
    $emulatorPath = "C:\Emulators\WinVICE\x64.exe"  # Τροποποίησε το μονοπάτι κατάλληλα
    $romFile = $romPathBox.Text

    if (-not (Test-Path $emulatorPath)) {
        [System.Windows.Forms.MessageBox]::Show("Emulator not found at path: $emulatorPath")
        return
    }

    if (-not (Test-Path $romFile)) {
        [System.Windows.Forms.MessageBox]::Show("ROM file not selected or does not exist.")
        return
    }

    Start-Process -FilePath $emulatorPath -ArgumentList "`"$romFile`""
})

# Τέλος
$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
