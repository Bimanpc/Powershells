Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "HTTPS Checker"
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter URL:"
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(100,20)
$form.Controls.Add($label)

# Create a textbox
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(120,20)
$textBox.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($textBox)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Check HTTPS"
$button.Location = New-Object System.Drawing.Point(100,60)
$button.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($button)

# Create a label for the result
$resultLabel = New-Object System.Windows.Forms.Label
$resultLabel.Location = New-Object System.Drawing.Point(10,100)
$resultLabel.Size = New-Object System.Drawing.Size(260,40)
$form.Controls.Add($resultLabel)

# Define the button click event
$button.Add_Click({
    $url = $textBox.Text
    if (-not [string]::IsNullOrEmpty($url)) {
        try {
            $request = [System.Net.WebRequest]::Create($url)
            $request.Method = "HEAD"
            $response = $request.GetResponse()
            $resultLabel.Text = "HTTPS is accessible."
            $response.Close()
        } catch {
            $resultLabel.Text = "HTTPS is not accessible or URL is invalid."
        }
    } else {
        $resultLabel.Text = "Please enter a URL."
    }
})

# Show the form
$form.ShowDialog()
