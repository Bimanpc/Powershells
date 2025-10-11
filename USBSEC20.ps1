Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function: Check current USB lock state
function Get-USBStatus {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
    $startValue = (Get-ItemProperty -Path $regPath -Name Start -ErrorAction SilentlyContinue).Start
    if ($startValue -eq 4) { return "Locked" }
    elseif ($startValue -eq 3) { return "Unlocked" }
    else { return "Unknown" }
}

# Function: Lock USB (disable storage devices)
function Lock-USB {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
    Set-ItemProperty -Path $regPath -Name Start -Value 4 -Force
}

# Function: Unlock USB (enable storage devices)
function Unlock-USB {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
    Set-ItemProperty -Path $regPath -Name Start -Value 3 -Force
}

# GUI Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "USB Security Locker"
$form.Size = New-Object System.Drawing.Size(350,200)
$form.StartPosition = "CenterScreen"

# Status Label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(30,30)
$lblStatus.Size = New-Object System.Drawing.Size(280,30)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$lblStatus.TextAlign = "MiddleCenter"
$form.Controls.Add($lblStatus)

# Lock Button
$btnLock = New-Object System.Windows.Forms.Button
$btnLock.Text = "Lock USB"
$btnLock.Location = New-Object System.Drawing.Point(50,80)
$btnLock.Size = New-Object System.Drawing.Size(100,40)
$btnLock.Add_Click({
    Lock-USB
    [System.Windows.Forms.MessageBox]::Show("USB Ports Locked!","USB Security")
    $lblStatus.Text = "Status: " + (Get-USBStatus)
})
$form.Controls.Add($btnLock)

# Unlock Button
$btnUnlock = New-Object System.Windows.Forms.Button
$btnUnlock.Text = "Unlock USB"
$btnUnlock.Location = New-Object System.Drawing.Point(180,80)
$btnUnlock.Size = New-Object System.Drawing.Size(100,40)
$btnUnlock.Add_Click({
    Unlock-USB
    [System.Windows.Forms.MessageBox]::Show("USB Ports Unlocked!","USB Security")
    $lblStatus.Text = "Status: " + (Get-USBStatus)
})
$form.Controls.Add($btnUnlock)

# Initialize Status
$lblStatus.Text = "Status: " + (Get-USBStatus)

# Run GUI
[void]$form.ShowDialog()
