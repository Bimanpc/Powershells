# Bluetooth Tracker GUI App (PowerShell + Windows Forms)
# Save as: BluetoothTracker.ps1
# Run: powershell -ExecutionPolicy Bypass -File BluetoothTracker.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Bluetooth Tracker"
$form.Size = New-Object System.Drawing.Size(700,500)
$form.StartPosition = "CenterScreen"

$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10,10)
$listView.Size = New-Object System.Drawing.Size(660,350)
$listView.View = "Details"
$listView.FullRowSelect = $true
$listView.Columns.Add("Device Name",200) | Out-Null
$listView.Columns.Add("Status",100) | Out-Null
$listView.Columns.Add("MAC Address",200) | Out-Null
$listView.Columns.Add("Last Seen",150) | Out-Null
$form.Controls.Add($listView)

$scanBtn = New-Object System.Windows.Forms.Button
$scanBtn.Text = "Scan Devices"
$scanBtn.Location = New-Object System.Drawing.Point(10,380)
$scanBtn.Size = New-Object System.Drawing.Size(150,40)
$form.Controls.Add($scanBtn)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Location = New-Object System.Drawing.Point(180,390)
$statusLabel.AutoSize = $true
$form.Controls.Add($statusLabel)

function Get-BluetoothDevices {
    $devices = Get-PnpDevice | Where-Object {
        $_.Class -match "Bluetooth"
    }

    $listView.Items.Clear()

    foreach ($dev in $devices) {
        $item = New-Object System.Windows.Forms.ListViewItem($dev.FriendlyName)

        $status =
            if ($dev.Status) { $dev.Status }
            else { "Unknown" }

        $item.SubItems.Add($status) | Out-Null
        $item.SubItems.Add($dev.InstanceId) | Out-Null
        $item.SubItems.Add((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null

        $listView.Items.Add($item) | Out-Null
    }

    $statusLabel.Text = "Found $($devices.Count) Bluetooth device(s)"
}

$scanBtn.Add_Click({
    $statusLabel.Text = "Scanning..."
    Get-BluetoothDevices
})

$form.Add_Shown({
    Get-BluetoothDevices
})

[void]$form.ShowDialog()
