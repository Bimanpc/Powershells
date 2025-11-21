Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === GUI Setup ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ubuntu Virtual PC Manager"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"

# === Buttons ===
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Ubuntu VM"
$btnStart.Location = New-Object System.Drawing.Point(50,50)
$btnStart.Size = New-Object System.Drawing.Size(120,40)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Stop Ubuntu VM"
$btnStop.Location = New-Object System.Drawing.Point(200,50)
$btnStop.Size = New-Object System.Drawing.Size(120,40)

# === Status Label ===
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: Idle"
$statusLabel.Location = New-Object System.Drawing.Point(50,120)
$statusLabel.Size = New-Object System.Drawing.Size(300,30)

# === Event Handlers ===
$btnStart.Add_Click({
    # Example: VirtualBox command to start VM
    $vmName = "UbuntuVM"
    Start-Process "VBoxManage" -ArgumentList "startvm `"$vmName`" --type headless"
    $statusLabel.Text = "Status: Ubuntu VM started"
})

$btnStop.Add_Click({
    $vmName = "UbuntuVM"
    Start-Process "VBoxManage" -ArgumentList "controlvm `"$vmName`" poweroff"
    $statusLabel.Text = "Status: Ubuntu VM stopped"
})

# === Add Controls ===
$form.Controls.Add($btnStart)
$form.Controls.Add($btnStop)
$form.Controls.Add($statusLabel)

# === Run GUI ===
[void]$form.ShowDialog()
