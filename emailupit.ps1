Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Email Sender"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create the labels and text boxes
$labelFrom = New-Object System.Windows.Forms.Label
$labelFrom.Text = "From:"
$labelFrom.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($labelFrom)

$textBoxFrom = New-Object System.Windows.Forms.TextBox
$textBoxFrom.Location = New-Object System.Drawing.Point(100, 20)
$textBoxFrom.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($textBoxFrom)

$labelTo = New-Object System.Windows.Forms.Label
$labelTo.Text = "To:"
$labelTo.Location = New-Object System.Drawing.Point(10, 50)
$form.Controls.Add($labelTo)

$textBoxTo = New-Object System.Windows.Forms.TextBox
$textBoxTo.Location = New-Object System.Drawing.Point(100, 50)
$textBoxTo.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($textBoxTo)

$labelSubject = New-Object System.Windows.Forms.Label
$labelSubject.Text = "Subject:"
$labelSubject.Location = New-Object System.Drawing.Point(10, 80)
$form.Controls.Add($labelSubject)

$textBoxSubject = New-Object System.Windows.Forms.TextBox
$textBoxSubject.Location = New-Object System.Drawing.Point(100, 80)
$textBoxSubject.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($textBoxSubject)

$labelBody = New-Object System.Windows.Forms.Label
$labelBody.Text = "Body:"
$labelBody.Location = New-Object System.Drawing.Point(10, 110)
$form.Controls.Add($labelBody)

$textBoxBody = New-Object System.Windows.Forms.TextBox
$textBoxBody.Location = New-Object System.Drawing.Point(100, 110)
$textBoxBody.Size = New-Object System.Drawing.Size(250, 100)
$textBoxBody.Multiline = $true
$form.Controls.Add($textBoxBody)

# Create the send button
$buttonSend = New-Object System.Windows.Forms.Button
$buttonSend.Text = "Send Email"
$buttonSend.Location = New-Object System.Drawing.Point(150, 220)
$buttonSend.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($buttonSend)

# Add the event handler for the send button
$buttonSend.Add_Click({
    $from = $textBoxFrom.Text
    $to = $textBoxTo.Text
    $subject = $textBoxSubject.Text
    $body = $textBoxBody.Text

    # Send the email
    try {
        Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer "smtp.office365.com"
        [System.Windows.Forms.MessageBox]::Show("Email sent successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to send email: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Show the form
$form.ShowDialog()
