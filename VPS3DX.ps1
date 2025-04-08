Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI SD Modeling App"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Model Parameters:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($label)

# Create a text box
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($textBox)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Run Model"
$button.Location = New-Object System.Drawing.Point(150, 100)
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Add_Click({
    # Placeholder for model execution code
    $message = "Model executed with parameters: " + $textBox.Text
    [System.Windows.Forms.MessageBox]::Show($message, "AI SD Modeling App")
})
$form.Controls.Add($button)

# Show the form
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
