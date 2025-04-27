Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Llama Chat App"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a text box for displaying chat history
$chatHistory = New-Object System.Windows.Forms.TextBox
$chatHistory.Multiline = $true
$chatHistory.ReadOnly = $true
$chatHistory.Size = New-Object System.Drawing.Size(380, 200)
$chatHistory.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($chatHistory)

# Create a text box for entering messages
$messageBox = New-Object System.Windows.Forms.TextBox
$messageBox.Size = New-Object System.Drawing.Size(280, 20)
$messageBox.Location = New-Object System.Drawing.Point(10, 220)
$form.Controls.Add($messageBox)

# Create a button to send messages
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = "Send"
$sendButton.Size = New-Object System.Drawing.Size(75, 23)
$sendButton.Location = New-Object System.Drawing.Point(300, 220)
$form.Controls.Add($sendButton)

# Add an event handler for the send button
$sendButton.Add_Click({
    $message = $messageBox.Text
    if ($message -ne "") {
        $chatHistory.AppendText("You: " + $message + "`n")
        $messageBox.Clear()

        # Simulate a response from the chatbot
        $response = "Llama: This is a simulated response to your message."
        $chatHistory.AppendText($response + "`n")
    }
})

# Show the form
$form.ShowDialog()
