Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WP Cyber Threat Checker (AI)"
$form.Size = New-Object System.Drawing.Size(500,300)

# URL Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "WordPress URL:"
$label.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label)

# URL Input
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(350,20)
$textBox.Location = New-Object System.Drawing.Point(120,20)
$form.Controls.Add($textBox)

# Output Box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.Size = New-Object System.Drawing.Size(460,150)
$outputBox.Location = New-Object System.Drawing.Point(10,100)
$form.Controls.Add($outputBox)

# Scan Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Scan Site"
$button.Location = New-Object System.Drawing.Point(120,60)

$button.Add_Click({
    $url = $textBox.Text

    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        $headers = $response.Headers

        $result = "Status Code: " + $response.StatusCode + "`n"

        # Basic checks
        if ($headers["X-Powered-By"]) {
            $result += "⚠ Exposes X-Powered-By header`n"
        }

        if ($response.Content -match "wp-content") {
            $result += "✔ WordPress detected`n"
        }

        if ($response.Content -match "wp-json") {
            $result += "⚠ REST API exposed`n"
        }

        # Send to LLM (example placeholder)
        $apiKey = "YOUR_API_KEY"
        $body = @{
            model = "gpt-4"
            messages = @(
                @{ role="system"; content="You are a cybersecurity analyst." },
                @{ role="user"; content="Analyze this scan result: $result" }
            )
        } | ConvertTo-Json -Depth 5

        $aiResponse = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Headers @{
                "Authorization" = "Bearer $apiKey"
                "Content-Type" = "application/json"
            } `
            -Method Post `
            -Body $body

        $analysis = $aiResponse.choices[0].message.content

        $outputBox.Text = $result + "`n--- AI Analysis ---`n" + $analysis
    }
    catch {
        $outputBox.Text = "Error scanning site."
    }
})

$form.Controls.Add($button)

# Run GUI
$form.ShowDialog()
