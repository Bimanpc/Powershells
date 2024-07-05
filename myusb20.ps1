function Show-MsgBoxCountDown {
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

    $form = New-Object System.Windows.Forms.Form
    $label = New-Object System.Windows.Forms.Label
    $label1 = New-Object System.Windows.Forms.Label
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $timer = New-Object System.Windows.Forms.Timer
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

    # Rest of the code (omitted for brevity)
}

function Check-USB {
    # Check for a USB, Get UserName and ComputerName from env variables
    $USB_Detected = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { ($_.DriveType -eq 2) -and ($_.DeviceID -ne "A:\") }

    if ($USB_Detected) {
        Show-MsgBoxCountDown
    }
}

# Call the function Check-USB
Check-USB
