Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PHP Checker"
$form.Size = New-Object System.Drawing.Size(300, 150)
$form.StartPosition = "CenterScreen"

# Create a label to display the result
$label = New-Object System.Windows.Forms.Label
$label.Size = New-Object System.Drawing.Size(250, 20)
$label.Location = New-Object System.Drawing.Point(25, 40)
$label.TextAlign = "MiddleCenter"
$form.Controls.Add($label)

# Create a button to check PHP
$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Text = "Check PHP"
$checkButton.Size = New-Object System.Drawing.Size(100, 30)
$checkButton.Location = New-Object System.Drawing.Point(100, 70)
$form.Controls.Add($checkButton)

# Define button click event
$checkButton.Add_Click({
    # Try to get PHP version
    $phpVersion = & php -v 2>&1
    
    # Check if PHP is installed by analyzing the output
    if ($phpVersion -match 'PHP ([\d\.]+)') {
        $version = $matches[1]
        $label.Text = "PHP is installed. Version: $version"
        $label.ForeColor = "Green"
    } else {
        $label.Text = "PHP is not installed."
        $label.ForeColor = "Red"
    }
})

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
