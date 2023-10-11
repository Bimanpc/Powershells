Add-Type -AssemblyName System.Windows.Forms

# Create a form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Happy Halloween!"
$Form.Size = New-Object System.Drawing.Size(300, 150)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

# Create a label to display the Halloween message
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Happy Halloween! Trick or treat!"
$Label.AutoSize = $true
$Label.Location = New-Object System.Drawing.Point(50, 30)

# Create a button
$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Click me!"
$Button.Location = New-Object System.Drawing.Point(100, 70)
$Button.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Boo! Happy Halloween!", "Halloween Greeting", "OK", [System.Windows.Forms.MessageBoxIcon]::Information)
})

# Add the controls to the form
$Form.Controls.Add($Label)
$Form.Controls.Add($Button)

# Show the form
$Form.ShowDialog()
