# Load the WinForms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Chatbox 2.0"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create a text box to display the chat messages
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.ReadOnly = $true
$textBox.ScrollBars = 'Vertical'
$textBox.Location = New-Object System.Drawing.Point(10, 10)
$textBox.Size = New-Object System.Drawing.Size(380, 200)
$form.Controls.Add($textBox)

# Create a text box for entering messages
$messageTextBox = New-Object System.Windows.Forms.TextBox
$messageTextBox.Location = New-Object System.Drawing.Point(10, 220)
$messageTextBox.Size = New-Object System.Drawing.Size(300, 30)
$form.Controls.Add($messageTextBox)

# Create a button to send messages
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Location = New-Object System.Drawing.Point(320, 220)
$sendButton.Size = New-Object System.Drawing.Size(70, 30)
$sendButton.Text = "Send"
$sendButton.Add_Click({
    $message = $messageTextBox.Text
    if ($message -ne "") {
        $textBox.AppendText("You: $message`r`n")
        # Here, you can send the message to another user or process it as needed.
        # For this simplified example, we just clear the message box.
        $messageTextBox.Text = ""
    }
})
$form.Controls.Add($sendButton)

# Show the form
$form.ShowDialog()
