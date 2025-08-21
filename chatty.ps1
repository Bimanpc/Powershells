Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Form setup ---
$form                   = New-Object System.Windows.Forms.Form
$form.Text              = "AI LLM Chat"
$form.Size              = New-Object System.Drawing.Size(600, 500)
$form.StartPosition     = "CenterScreen"

# --- Output box ---
$outputBox              = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline    = $true
$outputBox.ReadOnly     = $true
$outputBox.ScrollBars   = "Vertical"
$outputBox.WordWrap     = $true
$outputBox.Font         = 'Consolas,10'
$outputBox.Size         = New-Object System.Drawing.Size(560, 350)
$outputBox.Location     = New-Object System.Drawing.Point(10, 10)

# --- Input box ---
$inputBox               = New-Object System.Windows.Forms.TextBox
$inputBox.Size          = New-Object System.Drawing.Size(460, 20)
$inputBox.Location      = New-Object System.Drawing.Point(10, 370)

# --- Send button ---
$sendBtn                = New-Object System.Windows.Forms.Button
$sendBtn.Text           = "Send"
$sendBtn.Size           = New-Object System.Drawing.Size(75, 23)
$sendBtn.Location       = New-Object System.Drawing.Point(480, 368)

# --- Send action ---
$sendAction = {
    $userText = $inputBox.Text.Trim()
    if ($userText -ne "") {
        $outputBox.AppendText("You: $userText`r`n")
        $inputBox.Clear()

        # Replace this placeholder with your AI API call logic
        # Example:
        # $body = @{ prompt = $userText } | ConvertTo-Json
        # $aiResponse = Invoke-RestMethod -Uri "https://my-llm-endpoint" -Method Post -Body $body -ContentType "application/json"
        $aiResponse = "[LLM response placeholder]"

        $outputBox.AppendText("AI: $aiResponse`r`n`r`n")
    }
}

$sendBtn.Add_Click($sendAction)
$inputBox.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") {
        $sendAction.Invoke()
        $_.SuppressKeyPress = $true
    }
})

# --- Add controls ---
$form.Controls.Add($outputBox)
$form.Controls.Add($inputBox)
$form.Controls.Add($sendBtn)

# --- Run the form ---
[void]$form.ShowDialog()
