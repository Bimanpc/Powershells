Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI PDF Poster Maker"
$form.Size = New-Object System.Drawing.Size(500,400)

# Title Label
$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "Poster Title:"
$label1.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label1)

# Title TextBox
$titleBox = New-Object System.Windows.Forms.TextBox
$titleBox.Location = New-Object System.Drawing.Point(120,20)
$titleBox.Width = 300
$form.Controls.Add($titleBox)

# Description Label
$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "Description:"
$label2.Location = New-Object System.Drawing.Point(10,60)
$form.Controls.Add($label2)

# Description TextBox
$descBox = New-Object System.Windows.Forms.TextBox
$descBox.Location = New-Object System.Drawing.Point(120,60)
$descBox.Width = 300
$descBox.Height = 100
$descBox.Multiline = $true
$form.Controls.Add($descBox)

# Output Box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(10,200)
$outputBox.Width = 460
$outputBox.Height = 100
$outputBox.Multiline = $true
$form.Controls.Add($outputBox)

# Generate Button
$btn = New-Object System.Windows.Forms.Button
$btn.Text = "Generate Poster"
$btn.Location = New-Object System.Drawing.Point(10,320)

$btn.Add_Click({
    $title = $titleBox.Text
    $desc = $descBox.Text

    $apiKey = "YOUR_API_KEY"

    $body = @{
        model = "gpt-4.1-mini"
        messages = @(
            @{ role="user"; content="Create a poster text for: $title - $desc" }
        )
    } | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod `
        -Uri "https://api.openai.com/v1/chat/completions" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type"  = "application/json"
        } `
        -Body $body

    $result = $response.choices[0].message.content
    $outputBox.Text = $result

    # Save as PDF (basic)
    $filePath = "$env:USERPROFILE\Desktop\poster.txt"
    $result | Out-File $filePath

    [System.Windows.Forms.MessageBox]::Show("Poster saved to Desktop (TXT). Convert to PDF manually or extend script.")
})

$form.Controls.Add($btn)

# Run Form
$form.ShowDialog()
