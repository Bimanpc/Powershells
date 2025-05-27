Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows 10 Debloater"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Select the apps/features you want to remove:"
$form.Controls.Add($label)

# Create a checkbox for removing built-in apps
$checkBoxApps = New-Object System.Windows.Forms.CheckBox
$checkBoxApps.Location = New-Object System.Drawing.Point(20, 50)
$checkBoxApps.Size = New-Object System.Drawing.Size(350, 20)
$checkBoxApps.Text = "Remove built-in apps"
$form.Controls.Add($checkBoxApps)

# Create a checkbox for disabling telemetry
$checkBoxTelemetry = New-Object System.Windows.Forms.CheckBox
$checkBoxTelemetry.Location = New-Object System.Drawing.Point(20, 80)
$checkBoxTelemetry.Size = New-Object System.Drawing.Size(350, 20)
$checkBoxTelemetry.Text = "Disable telemetry"
$form.Controls.Add($checkBoxTelemetry)

# Create a button to apply changes
$buttonApply = New-Object System.Windows.Forms.Button
$buttonApply.Location = New-Object System.Drawing.Point(150, 120)
$buttonApply.Size = New-Object System.Drawing.Size(100, 30)
$buttonApply.Text = "Apply"
$buttonApply.Add_Click({
    if ($checkBoxApps.Checked) {
        # Command to remove built-in apps
        Get-AppxPackage -AllUsers | Where-Object {$_.Name -notlike "*Store*"} | Remove-AppxPackage
    }
    if ($checkBoxTelemetry.Checked) {
        # Command to disable telemetry
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
    }
    [System.Windows.Forms.MessageBox]::Show("Changes applied successfully!")
})
$form.Controls.Add($buttonApply)

# Show the form
$form.ShowDialog()
