Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ====== CONFIG ======
$apiKey = "YOUR_OPENAI_API_KEY"
$endpoint = "https://api.openai.com/v1/chat/completions"

# ====== FORM ======
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI Vibe Code IDE"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"

# ====== INPUT BOX ======
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Multiline = $true
$inputBox.ScrollBars = "Vertical"
$inputBox.Size = New-Object System.Drawing.Size(760,150)
$inputBox.Location = New-Object System.Drawing.Point(10,10)

# ====== OUTPUT BOX ======
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.Size = New-Object System.Drawing.Size(760,300)
$outputBox.Location = New-Object System.Drawing.Point(10,200)

# ====== BUTTON ======
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = "Send to AI"
$sendButton.Size = New-Object System.Drawing.Size(120,30)
$sendButton.Location = New-Object System.Drawing.Point(10,170)

# ====== FUNCTION ======
function Invoke-ChatGPT($prompt) {
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    }

    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "user"; content = $prompt }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
        return $response.choices[0].message.content
    } catch {
        return "Error: $_"
    }
}

# ====== BUTTON CLICK ======
$sendButton.Add_Click({
    $prompt = $inputBox.Text
    $outputBox.Text = "Thinking..."
    
    $result = Invoke-ChatGPT $prompt
    $outputBox.Text = $result
})

# ====== ADD CONTROLS ======
$form.Controls.Add($inputBox)
$form.Controls.Add($outputBox)
$form.Controls.Add($sendButton)

# ====== RUN ======
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
