Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "DPI Settings Changer"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Select DPI Scale:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a combo box
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10, 50)
$comboBox.Width = 260
$comboBox.Items.AddRange(@("100% (96 DPI)", "125% (120 DPI)", "150% (144 DPI)", "175% (168 DPI)", "200% (192 DPI)"))
$comboBox.SelectedIndex = 0
$form.Controls.Add($comboBox)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Apply"
$button.Location = New-Object System.Drawing.Point(10, 90)
$button.Add_Click({
    # Get the selected DPI value
    $selectedDPI = $comboBox.SelectedItem

    # Map the selected item to DPI value
    switch ($selectedDPI) {
        "100% (96 DPI)" { $dpiValue = 96 }
        "125% (120 DPI)" { $dpiValue = 120 }
        "150% (144 DPI)" { $dpiValue = 144 }
        "175% (168 DPI)" { $dpiValue = 168 }
        "200% (192 DPI)" { $dpiValue = 192 }
    }

    # Change the DPI setting
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LogPixels" -Value $dpiValue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win8DpiScaling" -Value 1

    # Notify the system of the change
    Stop-Process -Name "explorer" -Force
    Start-Process "explorer.exe"

    # Show a message box
    [System.Windows.Forms.MessageBox]::Show("DPI settings applied. You may need to log off and log back on for the changes to take effect.", "DPI Changer")
})
$form.Controls.Add($button)

# Show the form
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
