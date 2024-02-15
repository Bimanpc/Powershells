Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PC Health Check"
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"

# Create labels
$labelCPU = New-Object System.Windows.Forms.Label
$labelCPU.Text = "CPU Usage:"
$labelCPU.Location = New-Object System.Drawing.Point(10,30)
$labelMemory = New-Object System.Windows.Forms.Label
$labelMemory.Text = "Available Memory:"
$labelMemory.Location = New-Object System.Drawing.Point(10,60)
$labelDisk = New-Object System.Windows.Forms.Label
$labelDisk.Text = "Free Disk Space:"
$labelDisk.Location = New-Object System.Drawing.Point(10,90)

# Create textboxes
$textboxCPU = New-Object System.Windows.Forms.TextBox
$textboxCPU.Location = New-Object System.Drawing.Point(120,30)
$textboxCPU.Size = New-Object System.Drawing.Size(150,20)
$textboxMemory = New-Object System.Windows.Forms.TextBox
$textboxMemory.Location = New-Object System.Drawing.Point(120,60)
$textboxMemory.Size = New-Object System.Drawing.Size(150,20)
$textboxDisk = New-Object System.Windows.Forms.TextBox
$textboxDisk.Location = New-Object System.Drawing.Point(120,90)
$textboxDisk.Size = New-Object System.Drawing.Size(150,20)

# Create button
$buttonCheck = New-Object System.Windows.Forms.Button
$buttonCheck.Text = "Check PC Health"
$buttonCheck.Location = New-Object System.Drawing.Point(80,130)
$buttonCheck.Add_Click({
    # Function to retrieve system information
    function Get-SystemInfo {
        $cpuUsage = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty LoadPercentage
        $memory = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty FreePhysicalMemory
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID = 'C:'" | Select-Object -ExpandProperty FreeSpace

        $textboxCPU.Text = "$cpuUsage %"
        $textboxMemory.Text = "$memory KB"
        $textboxDisk.Text = "$disk bytes"
    }

    # Call the function
    Get-SystemInfo
})

# Add controls to form
$form.Controls.Add($labelCPU)
$form.Controls.Add($labelMemory)
$form.Controls.Add($labelDisk)
$form.Controls.Add($textboxCPU)
$form.Controls.Add($textboxMemory)
$form.Controls.Add($textboxDisk)
$form.Controls.Add($buttonCheck)

# Display the form
$form.ShowDialog()
