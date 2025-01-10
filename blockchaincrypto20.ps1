Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text = "Crypto Blockchain Chat"
$form.Size = New-Object Drawing.Size(400, 600)

$messagesListBox = New-Object Windows.Forms.ListBox
$messagesListBox.Size = New-Object Drawing.Size(360, 400)
$messagesListBox.Location = New-Object Drawing.Point(10, 10)

$messageTextBox = New-Object Windows.Forms.TextBox
$messageTextBox.Size = New-Object Drawing.Size(260, 20)
$messageTextBox.Location = New-Object Drawing.Point(10, 420)

$sendButton = New-Object Windows.Forms.Button
$sendButton.Text = "Send"
$sendButton.Size = New-Object Drawing.Size(75, 23)
$sendButton.Location = New-Object Drawing.Point(280, 420)
$sendButton.Add_Click({
    $message = $messageTextBox.Text
    if ($message -ne "") {
        $messagesListBox.Items.Add($message)
        $messageTextBox.Clear()
    }
})

$form.Controls.Add($messagesListBox)
$form.Controls.Add($messageTextBox)
$form.Controls.Add($sendButton)

$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
