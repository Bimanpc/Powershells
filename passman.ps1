Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Password Manager"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label and textbox for the password
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Password:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(120, 20)
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$textBox.PasswordChar = '*'
$form.Controls.Add($textBox)

# Create a button to save the password
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save Password"
$saveButton.Location = New-Object System.Drawing.Point(120, 60)
$saveButton.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($saveButton)

# Create a label to display the saved password
$displayLabel = New-Object System.Windows.Forms.Label
$displayLabel.Text = "Saved Password:"
$displayLabel.Location = New-Object System.Drawing.Point(10, 100)
$displayLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($displayLabel)

$displayTextBox = New-Object System.Windows.Forms.TextBox
$displayTextBox.Location = New-Object System.Drawing.Point(120, 100)
$displayTextBox.Size = New-Object System.Drawing.Size(200, 20)
$displayTextBox.ReadOnly = $true
$form.Controls.Add($displayTextBox)

# Add an event handler for the save button
$saveButton.Add_Click({
    $displayTextBox.Text = $textBox.Text
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
