# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SSD Check"
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"

# Create label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Click the button to check for SSDs:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10,30)
$form.Controls.Add($label)

# Create button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Check SSDs"
$button.Location = New-Object System.Drawing.Point(10,70)
$button.Add_Click({
    # PowerShell script logic for checking SSDs goes here
    $ssds = Get-PhysicalDisk | Where-Object MediaType -eq "SSD"
    if ($ssds) {
        [System.Windows.Forms.MessageBox]::Show("SSDs found:`n$($ssds.FriendlyName -join "`n")", "SSD Check", "OK", [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("No SSDs found.", "SSD Check", "OK", [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
