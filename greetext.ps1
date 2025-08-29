# Load WinForms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create the main window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ancient Greek LLM Text Editor"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"

# Input TextBox for raw Ancient Greek text
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Multiline   = $true
$inputBox.WordWrap    = $true
$inputBox.ScrollBars  = "Vertical"
$inputBox.Location    = New-Object System.Drawing.Point(10,10)
$inputBox.Size        = New-Object System.Drawing.Size(760,200)

# Button to invoke the LLM service
$button = New-Object System.Windows.Forms.Button
$button.Text     = "Edit Ancient Greek"
$button.Location = New-Object System.Drawing.Point(10,220)
$button.Size     = New-Object System.Drawing.Size(150,30)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text     = "Ready"
$statusLabel.Location = New-Object System.Drawing.Point(180,225)
$statusLabel.AutoSize = $true

# Output TextBox for the LLM-edited text
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline   = $true
$outputBox.WordWrap    = $true
$outputBox.ScrollBars  = "Vertical"
$outputBox.Location    = New-Object System.Drawing.Point(10,300)
$outputBox.Size        = New-Object System.Drawing.Size(760,200)
$outputBox.ReadOnly    = $true

# Add controls to the form
$form.Controls.AddRange(@($inputBox, $button, $statusLabel, $outputBox))

# Button click handler: call your LLM API endpoint
$button.Add_Click({
    $statusLabel.Text = "Processing..."
    $form.Refresh()

    $inputText = $inputBox.Text
    $apiUrl   = "https://api.your-llm-service.com/v1/generate"
    $apiKey   = "YOUR_API_KEY_HERE"  # Store this securely or load from env var

    $payload = @{
        model       = "ancient-greek-editor"
        prompt      = $inputText
        max_tokens  = 1024
        temperature = 0.7
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $apiUrl `
                                     -Method Post `
                                     -Headers @{
                                         "Authorization" = "Bearer $apiKey"
                                         "Content-Type"  = "application/json"
                                     } `
                                     -Body $payload

        # Adjust property access to match your service’s JSON schema
        $editedText = $response.choices[0].text
        $outputBox.Text = $editedText
        $statusLabel.Text = "Done"
    }
    catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
    }
})

# Show the GUI
[void]$form.ShowDialog()
