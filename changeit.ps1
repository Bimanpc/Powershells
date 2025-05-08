Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Microsoft Edge Start Page Changer"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Enter the new start page URL:"
$form.Controls.Add($label)

# Create a text box
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 50)
$textBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($textBox)

# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(10, 80)
$button.Size = New-Object System.Drawing.Size(360, 30)
$button.Text = "Set Start Page"
$button.Add_Click({
    $newUrl = $textBox.Text
    if ($newUrl -ne "") {
        # Here you would add the code to change the Microsoft Edge start page
        # This is a placeholder for the actual implementation
        [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Internet Explorer\Main", $true).SetValue("Start Page", $newUrl)
        [System.Windows.Forms.MessageBox]::Show("Start page has been set to: $newUrl", "Success")
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter a URL.", "Error")
    }
})
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
