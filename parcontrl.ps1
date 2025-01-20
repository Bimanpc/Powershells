Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a new form
$form = New-Object Windows.Forms.Form
$form.Text = "Parental Control App"
$form.Size = New-Object Drawing.Size(300, 200)

# Create a label
$label = New-Object Windows.Forms.Label
$label.Text = "Enter the application to block:"
$label.Location = New-Object Drawing.Point(10, 20)
$label.Size = New-Object Drawing.Size(200, 20)
$form.Controls.Add($label)

# Create a text box
$textBox = New-Object Windows.Forms.TextBox
$textBox.Location = New-Object Drawing.Point(10, 50)
$textBox.Size = New-Object Drawing.Size(200, 20)
$form.Controls.Add($textBox)

# Create a button
$button = New-Object Windows.Forms.Button
$button.Text = "Block Application"
$button.Location = New-Object Drawing.Point(10, 80)
$button.Size = New-Object Drawing.Size(100, 30)
$form.Controls.Add($button)

# Define the button click event
$button.Add_Click({
    $appName = $textBox.Text
    if (-not [string]::IsNullOrEmpty($appName)) {
        # Use taskkill to block the application
        Stop-Process -Name $appName -Force -ErrorAction SilentlyContinue
        [Windows.Forms.MessageBox]::Show("Application '$appName' has been blocked.")
    } else {
        [Windows.Forms.MessageBox]::Show("Please enter an application name.")
    }
})

# Run the form
[void] $form.ShowDialog()
