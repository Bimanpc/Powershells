Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ================= CONFIG =================
$TelegramBotToken = "YOUR_TELEGRAM_BOT_TOKEN"
$TelegramChatId   = "YOUR_CHAT_ID"

$LLMEndpoint = "http://localhost:11434/api/generate" # Example: Ollama
$LLMModel    = "llama3"

# =========================================

function Send-TelegramMessage {
    param ($Message)

    $url = "https://api.telegram.org/bot$TelegramBotToken/sendMessage"
    $body = @{
        chat_id = $TelegramChatId
        text    = $Message
    }

    Invoke-RestMethod -Uri $url -Method Post -Body $body -ErrorAction SilentlyContinue
}

function Invoke-LLM {
    param ($Prompt)

    $payload = @{
        model  = $LLMModel
        prompt = $Prompt
        stream = $false
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $LLMEndpoint -Method Post -Body $payload -ContentType "application/json"
        return $response.response
    }
    catch {
        return "LLM error: $_"
    }
}

# ================= GUI =================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Telegram AI LLM Client"
$form.Size = New-Object System.Drawing.Size(600,500)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Multiline = $true
$inputBox.Size = New-Object System.Drawing.Size(540,100)
$inputBox.Location = New-Object System.Drawing.Point(20,20)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Size = New-Object System.Drawing.Size(540,250)
$outputBox.Location = New-Object System.Drawing.Point(20,140)

$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = "Send to AI → Telegram"
$sendButton.Size = New-Object System.Drawing.Size(200,40)
$sendButton.Location = New-Object System.Drawing.Point(20,410)

$sendButton.Add_Click({
    $prompt = $inputBox.Text
    if (!$prompt) { return }

    $outputBox.AppendText("User:`r`n$prompt`r`n`r`n")

    $aiResponse = Invoke-LLM -Prompt $prompt
    $outputBox.AppendText("AI:`r`n$aiResponse`r`n`r`n")

    Send-TelegramMessage -Message $aiResponse
})

$form.Controls.Add($inputBox)
$form.Controls.Add($outputBox)
$form.Controls.Add($sendButton)

$form.ShowDialog()
