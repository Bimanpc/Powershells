Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================
# CONFIGURATION
# ==========================

# TODO: Replace with your real LLM endpoint and key
$Global:LLM_Endpoint = "https://api.example.com/v1/chat/completions"
$Global:LLM_ApiKey   = "YOUR_API_KEY_HERE"

# Simple helper to call an LLM API (placeholder)
function Invoke-LLM {
    param(
        [string]$Prompt
    )

    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        return "Please type something first."
    }

    try {
        # Example JSON body for a chat-style LLM
        $body = @{
            model    = "your-model-name"
            messages = @(
                @{
                    role    = "system"
                    content = "You are a communication assistant for an autistic user. 
                               You suggest clear, concrete, low-sensory, and respectful 
                               alternative phrasings for what they want to say."
                },
                @{
                    role    = "user"
                    content = $Prompt
                }
            )
        } | ConvertTo-Json -Depth 5

        $headers = @{
            "Authorization" = "Bearer $($Global:LLM_ApiKey)"
            "Content-Type"  = "application/json"
        }

        $response = Invoke-RestMethod -Uri $Global:LLM_Endpoint -Method Post -Headers $headers -Body $body

        # Adjust this path depending on your LLM provider’s response format
        $text = $response.choices[0].message.content
        return $text
    }
    catch {
        return "Error contacting AI service: $($_.Exception.Message)"
    }
}

# ==========================
# GUI SETUP
# ==========================

$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "AI Keyboard Helper"
$form.StartPosition   = "CenterScreen"
$form.Size            = New-Object System.Drawing.Size(800, 600)
$form.BackColor       = [System.Drawing.Color]::FromArgb(245,245,245)
$form.Font            = New-Object System.Drawing.Font("Segoe UI", 11)

# Label: Instructions
$labelInstructions              = New-Object System.Windows.Forms.Label
$labelInstructions.Text         = "Type what you want to say. Then click 'Get Suggestions'."
$labelInstructions.AutoSize     = $true
$labelInstructions.Location     = New-Object System.Drawing.Point(20, 20)
$labelInstructions.ForeColor    = [System.Drawing.Color]::FromArgb(30,30,30)
$form.Controls.Add($labelInstructions)

# Input TextBox
$textInput                      = New-Object System.Windows.Forms.TextBox
$textInput.Multiline            = $true
$textInput.ScrollBars           = "Vertical"
$textInput.Location             = New-Object System.Drawing.Point(20, 60)
$textInput.Size                 = New-Object System.Drawing.Size(740, 150)
$textInput.BackColor            = [System.Drawing.Color]::White
$textInput.ForeColor            = [System.Drawing.Color]::FromArgb(20,20,20)
$form.Controls.Add($textInput)

# Button: Get Suggestions
$buttonSuggest                  = New-Object System.Windows.Forms.Button
$buttonSuggest.Text             = "Get Suggestions"
$buttonSuggest.Location         = New-Object System.Drawing.Point(20, 225)
$buttonSuggest.Size             = New-Object System.Drawing.Size(160, 40)
$buttonSuggest.BackColor        = [System.Drawing.Color]::FromArgb(220, 235, 255)
$buttonSuggest.FlatStyle        = "Flat"
$buttonSuggest.FlatAppearance.BorderSize = 0
$form.Controls.Add($buttonSuggest)

# Label: Suggestions
$labelSuggestions               = New-Object System.Windows.Forms.Label
$labelSuggestions.Text          = "AI Suggestions:"
$labelSuggestions.AutoSize      = $true
$labelSuggestions.Location      = New-Object System.Drawing.Point(20, 280)
$labelSuggestions.ForeColor     = [System.Drawing.Color]::FromArgb(30,30,30)
$form.Controls.Add($labelSuggestions)

# Suggestions TextBox (read-only)
$textSuggestions                = New-Object System.Windows.Forms.TextBox
$textSuggestions.Multiline      = $true
$textSuggestions.ScrollBars     = "Vertical"
$textSuggestions.Location       = New-Object System.Drawing.Point(20, 310)
$textSuggestions.Size           = New-Object System.Drawing.Size(740, 200)
$textSuggestions.ReadOnly       = $true
$textSuggestions.BackColor      = [System.Drawing.Color]::FromArgb(250,250,250)
$textSuggestions.ForeColor      = [System.Drawing.Color]::FromArgb(20,20,20)
$form.Controls.Add($textSuggestions)

# ==========================
# EVENT HANDLERS
# ==========================

$buttonSuggest.Add_Click({
    $buttonSuggest.Enabled = $false
    $buttonSuggest.Text    = "Thinking..."
    $form.Cursor           = [System.Windows.Forms.Cursors]::WaitCursor

    $prompt = $textInput.Text

    # Run LLM call in a background job-like way to keep UI responsive
    $job = [System.ComponentModel.BackgroundWorker]::new()
    $job.WorkerSupportsCancellation = $false

    $job.DoWork += {
        param($sender, $e)
        $e.Result = Invoke-LLM -Prompt $prompt
    }

    $job.RunWorkerCompleted += {
        param($sender, $e)
        $textSuggestions.Text = $e.Result
        $buttonSuggest.Enabled = $true
        $buttonSuggest.Text    = "Get Suggestions"
        $form.Cursor           = [System.Windows.Forms.Cursors]::Default
        $job.Dispose()
    }

    $job.RunWorkerAsync()
})

# ==========================
# RUN
# ==========================

[void]$form.ShowDialog()
