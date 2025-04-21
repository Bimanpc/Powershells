Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Geolocation App"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter an address:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a text box
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($textBox)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Get Geolocation"
$button.Location = New-Object System.Drawing.Point(10, 80)
$button.Size = New-Object System.Drawing.Size(360, 30)
$form.Controls.Add($button)

# Create a label for the result
$resultLabel = New-Object System.Windows.Forms.Label
$resultLabel.Location = New-Object System.Drawing.Point(10, 120)
$resultLabel.Size = New-Object System.Drawing.Size(360, 60)
$form.Controls.Add($resultLabel)

# Define the button click event
$button.Add_Click({
    $address = $textBox.Text
    if (-not [string]::IsNullOrWhiteSpace($address)) {
        # Here you would call your geolocation API and get the result
        $result = "Geolocation data for: $address" # Replace with actual API call result
        $resultLabel.Text = $result
    } else {
        $resultLabel.Text = "Please enter a valid address."
    }
})

# Show the form
$form.ShowDialog()
