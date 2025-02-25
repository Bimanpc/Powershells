# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Starlink Settings"
$form.Size = New-Object System.Drawing.Size(300, 200)

# Create a button to check connection status
$checkStatusButton = New-Object System.Windows.Forms.Button
$checkStatusButton.Text = "Check Connection Status"
$checkStatusButton.Location = New-Object System.Drawing.Point(50, 50)
$checkStatusButton.Size = New-Object System.Drawing.Size(200, 30)
$checkStatusButton.Add_Click({
    # Add your code to check connection status here
    [System.Windows.Forms.MessageBox]::Show("Checking connection status...")
})
$form.Controls.Add($checkStatusButton)

# Create a button to restart the router
$restartRouterButton = New-Object System.Windows.Forms.Button
$restartRouterButton.Text = "Restart Router"
$restartRouterButton.Location = New-Object System.Drawing.Point(50, 100)
$restartRouterButton.Size = New-Object System.Drawing.Size(200, 30)
$restartRouterButton.Add_Click({
    # Add your code to restart the router here
    [System.Windows.Forms.MessageBox]::Show("Restarting router...")
})
$form.Controls.Add($restartRouterButton)

# Show the form
$form.ShowDialog()
