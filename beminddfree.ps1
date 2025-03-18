Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Destress App"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(100, 80)
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Text = "Destress"

# Add a click event handler for the button
$button.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Take a deep breath and relax. You're doing great!", "Destress Tip")
})

# Add the button to the form
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
