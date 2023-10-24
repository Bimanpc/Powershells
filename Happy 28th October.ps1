Add-Type -TypeDefinition @"
    using System;
    using System.Windows.Forms;
"@

# Create a new form
$form = New-Object Windows.Forms.Form
$form.Text = "Happy 28th October"

# Create a label to display the message
$label = New-Object Windows.Forms.Label
$label.Text = "Happy 28th October!!!!!"
$label.AutoSize = $true
$label.Location = New-Object Drawing.Point(50, 50)

# Add the label to the form
$form.Controls.Add($label)

# Show the form
$form.ShowDialog()
