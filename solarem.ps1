Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === FORM ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI Solaris Terminal"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"
$form.BackColor = "Black"

# === OUTPUT BOX (Terminal) ===
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Size = New-Object System.Drawing.Size(760,400)
$outputBox.Location = New-Object System.Drawing.Point(10,10)
$outputBox.BackColor = "Black"
$outputBox.ForeColor = "Lime"
$outputBox.Font = New-Object System.Drawing.Font("Consolas",10)
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# === INPUT BOX ===
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Size = New-Object System.Drawing.Size(600,30)
$inputBox.Location = New-Object System.Drawing.Point(10,420)
$inputBox.BackColor = "Black"
$inputBox.ForeColor = "Lime"
$inputBox.Font = New-Object System.Drawing.Font("Consolas",10)
$form.Controls.Add($inputBox)

# === SEND BUTTON ===
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = "Execute"
$sendButton.Size = New-Object System.Drawing.Size(80,30)
$sendButton.Location = New-Object System.Drawing.Point(620,420)
$form.Controls.Add($sendButton)

# === CLEAR BUTTON ===
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear"
$clearButton.Size = New-Object System.Drawing.Size(70,30)
$clearButton.Location = New-Object System.Drawing.Point(710,420)
$form.Controls.Add($clearButton)

# === EXIT BUTTON ===
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(70,30)
$exitButton.Location = New-Object System.Drawing.Point(710,460)
$form.Controls.Add($exitButton)

# === API SETTINGS ===
$API_KEY = "YOUR_API_KEY_HERE"
$API_URL = "https://api.openai.com/v1/chat/completions"

function Ask-AI($prompt) {
    $headers = @{
        "Authorization" = "Bearer $API_KEY"
        "Content-Type"  = "application/json"
    }

    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = "You are a UNIX Solaris terminal assistant." },
            @{ role = "user"; content = $prompt }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri $API_URL -Method Post -Headers $headers -Body $body
        return $response.choices[0].message.content
    }
    catch {
        return "ERROR: $($_.Exception.Message)"
    }
}

# === BUTTON EVENTS ===
$sendButton.Add_Click({
    $cmd = $inputBox.Text
    if ($cmd -ne "") {
        $outputBox.AppendText("`n> $cmd`n")
        $response = Ask-AI $cmd
        $outputBox.AppendText("$response`n")
        $inputBox.Clear()
    }
})

$clearButton.Add_Click({
    $outputBox.Clear()
})

$exitButton.Add_Click({
    $form.Close()
})

# ENTER KEY SUPPORT
$inputBox.Add_KeyDown({
    if ($_.KeyCode -eq "Enter") {
        $sendButton.PerformClick()
    }
})

# === RUN ===
[void]$form.ShowDialog()
