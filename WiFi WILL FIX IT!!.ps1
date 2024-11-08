Add-Type -AssemblyName System.Windows.Forms

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows 10 Wi-Fi Fixer"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select an option to troubleshoot your Wi-Fi:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($label)

# Reset Network Button
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Text = "Reset Network Adapter"
$resetButton.Size = New-Object System.Drawing.Size(150, 40)
$resetButton.Location = New-Object System.Drawing.Point(10, 50)
$resetButton.Add_Click({
    Write-Host "Resetting Network Adapter..."
    Stop-Service -Name "NetAdapter" -Force
    Start-Sleep -Seconds 2
    Start-Service -Name "NetAdapter"
    [System.Windows.Forms.MessageBox]::Show("Network Adapter reset successfully!", "Action Completed", "OK", "Information")
})
$form.Controls.Add($resetButton)

# Clear DNS Cache Button
$dnsButton = New-Object System.Windows.Forms.Button
$dnsButton.Text = "Clear DNS Cache"
$dnsButton.Size = New-Object System.Drawing.Size(150, 40)
$dnsButton.Location = New-Object System.Drawing.Point(10, 100)
$dnsButton.Add_Click({
    Write-Host "Clearing DNS Cache..."
    ipconfig /flushdns | Out-Null
    [System.Windows.Forms.MessageBox]::Show("DNS Cache cleared successfully!", "Action Completed", "OK", "Information")
})
$form.Controls.Add($dnsButton)

# Check Network Status Button
$statusButton = New-Object System.Windows.Forms.Button
$statusButton.Text = "Check Network Status"
$statusButton.Size = New-Object System.Drawing.Size(150, 40)
$statusButton.Location = New-Object System.Drawing.Point(10, 150)
$statusButton.Add_Click({
    Write-Host "Checking Network Status..."
    $status = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if ($status) {
        [System.Windows.Forms.MessageBox]::Show("Network is connected.", "Status", "OK", "Information")
    } else {
        [System.Windows.Forms.MessageBox]::Show("Network is disconnected.", "Status", "OK", "Warning")
    }
})
$form.Controls.Add($statusButton)

# Exit Button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(150, 40)
$exitButton.Location = New-Object System.Drawing.Point(10, 200)
$exitButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($exitButton)

# Run Form
$form.ShowDialog()
