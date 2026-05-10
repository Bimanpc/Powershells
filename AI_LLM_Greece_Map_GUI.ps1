
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# Configuration
# -----------------------------
# Set your API key here or use environment variable OPENAI_API_KEY
$ApiKey = $env:OPENAI_API_KEY

# -----------------------------
# Helper: Call OpenAI-compatible API
# -----------------------------
function Invoke-LLM {
    param(
        [string]$Prompt
    )

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        return "OPENAI_API_KEY environment variable is not set.`r`n`r`nPrompt received:`r`n$Prompt"
    }

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type"  = "application/json"
    }

    $body = @{
        model = "gpt-4.1-mini"
        messages = @(
            @{
                role = "system"
                content = "You are a helpful assistant specializing in Greece geography, tourism, and mapping."
            },
            @{
                role = "user"
                content = $Prompt
            }
        )
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Method Post `
            -Headers $headers `
            -Body $body

        return $response.choices[0].message.content
    }
    catch {
        return "API Error:`r`n$($_.Exception.Message)"
    }
}

# -----------------------------
# GUI
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI LLM Greece Map Assistant"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.StartPosition = "CenterScreen"

# Left panel
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Dock = "Left"
$leftPanel.Width = 420
$leftPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($leftPanel)

# Prompt label
$lblPrompt = New-Object System.Windows.Forms.Label
$lblPrompt.Text = "Ask about Greece (cities, islands, routes, history):"
$lblPrompt.AutoSize = $true
$lblPrompt.Top = 10
$lblPrompt.Left = 10
$leftPanel.Controls.Add($lblPrompt)

# Prompt textbox
$txtPrompt = New-Object System.Windows.Forms.TextBox
$txtPrompt.Multiline = $true
$txtPrompt.ScrollBars = "Vertical"
$txtPrompt.Width = 380
$txtPrompt.Height = 120
$txtPrompt.Top = 35
$txtPrompt.Left = 10
$txtPrompt.Text = "Tell me about Athens and show it on the map."
$leftPanel.Controls.Add($txtPrompt)

# Location label
$lblLocation = New-Object System.Windows.Forms.Label
$lblLocation.Text = "Map location (city or island):"
$lblLocation.AutoSize = $true
$lblLocation.Top = 170
$lblLocation.Left = 10
$leftPanel.Controls.Add($lblLocation)

# Location textbox
$txtLocation = New-Object System.Windows.Forms.TextBox
$txtLocation.Width = 380
$txtLocation.Top = 195
$txtLocation.Left = 10
$txtLocation.Text = "Athens, Greece"
$leftPanel.Controls.Add($txtLocation)

# Buttons
$btnAsk = New-Object System.Windows.Forms.Button
$btnAsk.Text = "Ask AI"
$btnAsk.Width = 120
$btnAsk.Top = 230
$btnAsk.Left = 10
$leftPanel.Controls.Add($btnAsk)

$btnMap = New-Object System.Windows.Forms.Button
$btnMap.Text = "Show Map"
$btnMap.Width = 120
$btnMap.Top = 230
$btnMap.Left = 140
$leftPanel.Controls.Add($btnMap)

# Output textbox
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.ReadOnly = $true
$txtOutput.Width = 380
$txtOutput.Height = 480
$txtOutput.Top = 270
$txtOutput.Left = 10
$leftPanel.Controls.Add($txtOutput)

# Web browser (map)
$browser = New-Object System.Windows.Forms.WebBrowser
$browser.Dock = "Fill"
$form.Controls.Add($browser)

# Load default map
$browser.Navigate("https://www.openstreetmap.org/search?query=Greece")

# Button events
$btnMap.Add_Click({
    $location = [System.Uri]::EscapeDataString($txtLocation.Text)
    $browser.Navigate("https://www.openstreetmap.org/search?query=$location")
})

$btnAsk.Add_Click({
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $txtOutput.Text = "Thinking..."
    [System.Windows.Forms.Application]::DoEvents()

    $answer = Invoke-LLM -Prompt $txtPrompt.Text
    $txtOutput.Text = $answer

    # If the location box is empty, use the prompt as a search term.
    $search = if ([string]::IsNullOrWhiteSpace($txtLocation.Text)) {
        $txtPrompt.Text
    } else {
        $txtLocation.Text
    }

    $search = [System.Uri]::EscapeDataString($search)
    $browser.Navigate("https://www.openstreetmap.org/search?query=$search")

    $form.Cursor = [System.Windows.Forms.Cursors]::Default
})

# Run
[void]$form.ShowDialog()
