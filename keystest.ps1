# Define the form
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object Windows.Forms.Form
$form.Text = "Keyboard Test"
$form.Size = New-Object Drawing.Size @(300, 200)
$form.StartPosition = "CenterScreen"

# Define a label for displaying the pressed key
$label = New-Object Windows.Forms.Label
$label.Location = New-Object Drawing.Point @(10, 10)
$label.Size = New-Object Drawing.Size @(280, 30)
$label.Text = "Press a key..."
$form.Controls.Add($label)

# Event handler for key press
$keyPressed = {
    param($sender, $e)
    $label.Text = "Pressed Key: $($e.KeyCode)"
}

# Add key press event to the form
$form.Add_KeyDown($keyPressed)

# Show the form
$form.ShowDialog()
