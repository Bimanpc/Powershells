Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WHOIS Lookup"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Domain or IP:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Create a textbox
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(150, 20)
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Lookup"
$button.Location = New-Object System.Drawing.Point(150, 60)
$form.Controls.Add($button)

# Create a textbox for output
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(10, 100)
$outputBox.Size = New-Object System.Drawing.Size(360, 150)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$form.Controls.Add($outputBox)

# Add button click event
$button.Add_Click({
    $domain = $textBox.Text
    if ($domain) {
        $whoisResult = whois $domain
        $outputBox.Text = $whoisResult
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter a domain or IP address.")
    }
})

# Show the form
$form.ShowDialog()
