Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$mainForm = New-Object Windows.Forms.Form
$mainForm.Text = "Network Tools"
$mainForm.Width = 400
$mainForm.Height = 200
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false

# Create the label and textbox for input
$label = New-Object Windows.Forms.Label
$label.Text = "Enter IP Address or Hostname:"
$label.AutoSize = $true
$label.Top = 20
$label.Left = 20

$textBox = New-Object Windows.Forms.TextBox
$textBox.Top = $label.Bottom + 10
$textBox.Left = 20
$textBox.Width = $mainForm.Width - 40

# Create the "Ping" button
$pingButton = New-Object Windows.Forms.Button
$pingButton.Text = "Ping"
$pingButton.Top = $textBox.Bottom + 20
$pingButton.Left = $mainForm.Width / 2 - $pingButton.Width / 2
$pingButton.Add_Click({
    $target = $textBox.Text
    $result = Test-Connection -ComputerName $target -Count 4 -ErrorAction SilentlyContinue
    if ($result) {
        $pingResult = "Ping to $target successful`n"
        $pingResult += "Average Response Time: $($result | Measure-Object ResponseTime -Average).Average ms"
    } else {
        $pingResult = "Ping to $target failed."
    }
    [System.Windows.Forms.MessageBox]::Show($pingResult, "Ping Result")
})

# Add controls to the form
$mainForm.Controls.Add($label)
$mainForm.Controls.Add($textBox)
$mainForm.Controls.Add($pingButton)

# Show the form
$mainForm.ShowDialog()
