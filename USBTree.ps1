Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to get USB devices and their tree structure
function Get-UsbTree {
    $usbDevices = Get-WmiObject Win32_USBControllerDevice | ForEach-Object {
        $_ | Get-WmiObject -Class Win32_PnPEntity
    }

    $usbTree = @{}
    
    foreach ($device in $usbDevices) {
        $parentDevice = Get-UsbParentDevice $device
        $usbTree[$device.DeviceID] = @{
            DeviceName = $device.Name
            ParentDevice = $parentDevice
        }
    }

    return $usbTree
}

# Function to get the parent USB device of a given device
function Get-UsbParentDevice($device) {
    $parentDevice = Get-WmiObject Win32_PnPEntity | Where-Object { $_.DeviceID -eq $device.PNPDeviceID }
    return $parentDevice.Name
}

# Function to create a DataGridView control
function Create-DataGridView {
    $dataGridView = New-Object Windows.Forms.DataGridView
    $dataGridView.Dock = 'Fill'
    $dataGridView.AutoSizeColumnsMode = 'Fill'
    $dataGridView.RowHeadersVisible = $false
    $dataGridView.AllowUserToAddRows = $false
    return $dataGridView
}

# Function to populate DataGridView with USB tree information
function Populate-DataGridView($dataGridView, $usbTree) {
    $dataGridView.Rows.Clear()

    foreach ($usbDevice in $usbTree.Keys) {
        $deviceInfo = $usbTree[$usbDevice]
        $dataGridView.Rows.Add($usbDevice, $deviceInfo.DeviceName, $deviceInfo.ParentDevice)
    }
}

# Create main form
$form = New-Object Windows.Forms.Form
$form.Text = 'USB Tree Viewer'
$form.Size = New-Object Drawing.Size(600, 400)

# Create DataGridView
$dataGridView = Create-DataGridView
$form.Controls.Add($dataGridView)

# Add event handler for form load
$form.Add_Load({
    $usbTree = Get-UsbTree
    Populate-DataGridView $dataGridView $usbTree
})

# Show the form
$form.ShowDialog()
