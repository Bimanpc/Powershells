Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "Joomla Security Audit Tool"
$form.Size = New-Object System.Drawing.Size(400,300)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(20,20)
$inputBox.Width = 250
$form.Controls.Add($inputBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Scan"
$button.Location = New-Object System.Drawing.Point(280,20)

$button.Add_Click({
    $url = $inputBox.Text
    Invoke-WebRequest -Uri $url -UseBasicParsing
    [System.Windows.Forms.MessageBox]::Show("Scan completed (basic check)")
})

$form.Controls.Add($button)
$form.ShowDialog()
