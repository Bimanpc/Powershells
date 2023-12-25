Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object Windows.Forms.Form
$form.Text = "Merry Christmas!"
$form.Size = New-Object Drawing.Size(300,150)
$form.StartPosition = "CenterScreen"

# Create label
$label = New-Object Windows.Forms.Label
$label.Text = "Wishing you a Merry Christmas and a Happy New Year!"
$label.AutoSize = $true
$label.Location = New-Object Drawing.Point(50, 20)

# Add label to form
$form.Controls.Add($label)

# Show form
$form.ShowDialog()
