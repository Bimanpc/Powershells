Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SSL Checker"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Create a Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter URL:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(80, 20)
$form.Controls.Add($label)

# Create a TextBox
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(120, 20)
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox)

# Create a Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Check SSL"
$button.Location = New-Object System.Drawing.Point(120, 60)
$button.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($button)

# Create a Result Label
$resultLabel = New-Object System.Windows.Forms.Label
$resultLabel.Location = New-Object System.Drawing.Point(20, 100)
$resultLabel.Size = New-Object System.Drawing.Size(350, 50)
$form.Controls.Add($resultLabel)

# Function to Check SSL
$button.Add_Click({
    $url = $textBox.Text
    if (-not $url) {
        $resultLabel.Text = "Please enter a URL."
        return
    }
    
    try {
        $request = [Net.HttpWebRequest]::Create("https://$url")
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $certificate = $request.ServicePoint.Certificate
        $expiryDate = [datetime]::Parse($certificate.GetExpirationDateString())
        $resultLabel.Text = "SSL is valid until: $expiryDate"
    } catch {
        $resultLabel.Text = "Failed to retrieve SSL information."
    }
})

# Show the Form
[void]$form.ShowDialog()
