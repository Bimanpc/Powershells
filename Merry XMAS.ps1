Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = "Merry Christmas"
$form.Size = New-Object Drawing.Size @(300,150)

# Create a label with the message
$label = New-Object Windows.Forms.Label
$label.Text = "Merry Christmas!"
$label.AutoSize = $true
$label.Location = New-Object Drawing.Point @(75, 30)

# Add the label to the form
$form.Controls.Add($label)

# Show the form
$form.ShowDialog()
