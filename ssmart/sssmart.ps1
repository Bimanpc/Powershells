# Load necessary assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to get SSD SMART data
function Get-SmartData {
    $disks = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' }
    $diskInfo = @()

    foreach ($disk in $disks) {
        $health = $disk.HealthStatus
        $model = $disk.Model
        $firmware = $disk.FirmwareVersion
        $size = [math]::round($disk.Size / 1GB, 2)
        $serial = $disk.SerialNumber
        $temp = Get-StorageReliabilityCounter -PhysicalDisk $disk.DeviceId | Select-Object -ExpandProperty Temperature

        $diskInfo += [PSCustomObject]@{
            Model       = $model
            Firmware    = $firmware
            SizeGB      = $size
            Serial      = $serial
            HealthStatus= $health
            Temperature = $temp
        }
    }
    return $diskInfo
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SSD SMART Status"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Create a DataGridView to display the SMART data
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Size = New-Object System.Drawing.Size(580, 300)
$grid.Location = New-Object System.Drawing.Point(10, 10)
$grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill

# Add DataGridView to the form
$form.Controls.Add($grid)

# Create a button to refresh the SMART data
$button = New-Object System.Windows.Forms.Button
$button.Text = "Refresh"
$button.Location = New-Object System.Drawing.Point(10, 320)
$button.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($button)

# Define button click event
$button.Add_Click({
    $grid.DataSource = Get-SmartData()
})

# Load initial data
$grid.DataSource = Get-SmartData()

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
