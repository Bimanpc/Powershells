Add-Type -AssemblyName System.Windows.Forms

# Function to get GPU information using PowerShell
Function Get-GPUInfo {
    # Run PowerShell command to get GPU information
    $gpuInfo = Get-CimInstance -ClassName Win32_VideoController
    
    # Build a string with GPU information
    $infoString = ""
    Foreach ($gpu in $gpuInfo) {
        $infoString += "Device: $($gpu.Caption)`n"
        $infoString += "Driver Version: $($gpu.DriverVersion)`n"
        $infoString += "Video Processor: $($gpu.VideoProcessor)`n`n"
    }
    
    return $infoString
}

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "GPU Information"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"

# Create a label to display GPU information
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(380, 280)
$label.Font = New-Object System.Drawing.Font("Arial", 12)
$label.Text = Get-GPUInfo

# Add the label to the form
$form.Controls.Add($label)

# Show the form
$form.ShowDialog()
