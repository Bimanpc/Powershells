# Load the WinForms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Net Tools"
$form.Size = New-Object System.Drawing.Size(400, 200)

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(120, 20)
$label.Text = "Enter IP Addressss:"
$form.Controls.Add($label)

# Create a text box for entering IP address
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(140, 20)
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox)

# Create a button for pinging the IP address
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(140, 50)
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Text = "Ping"
$button.Add_Click({
    $ip = $textBox.Text
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        [System.Windows.Forms.MessageBox]::Show("Ping successful!", "Result", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Ping failed.", "Result", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
