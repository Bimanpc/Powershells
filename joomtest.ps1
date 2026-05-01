Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Joomla Security Scanner (Authorized Use Only)"
$form.Size = New-Object System.Drawing.Size(500,400)

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Target URL:"
$label.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label)

# Input Box
$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Size = New-Object System.Drawing.Size(350,20)
$textbox.Location = New-Object System.Drawing.Point(100,20)
$form.Controls.Add($textbox)

# Output Box
$output = New-Object System.Windows.Forms.TextBox
$output.Multiline = $true
$output.ScrollBars = "Vertical"
$output.Size = New-Object System.Drawing.Size(460,250)
$output.Location = New-Object System.Drawing.Point(10,80)
$form.Controls.Add($output)

# Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Scan"
$button.Location = New-Object System.Drawing.Point(200,50)

# Scan Function (SAFE checks only)
$button.Add_Click({
    $url = $textbox.Text
    $output.Clear()

    if (-not $url) {
        $output.Text = "Please enter a valid URL"
        return
    }

    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing

        # Basic checks
        $output.AppendText("Status Code: $($response.StatusCode)`r`n")

        # Header check
        if ($response.Headers["X-Content-Type-Options"] -eq $null) {
            $output.AppendText("[!] Missing X-Content-Type-Options header`r`n")
        }

        # Joomla detection
        if ($response.Content -match "Joomla!") {
            $output.AppendText("[+] Joomla detected`r`n")
        }

        # robots.txt check
        try {
            $robots = Invoke-WebRequest -Uri "$url/robots.txt" -UseBasicParsing
            $output.AppendText("[+] robots.txt found`r`n")
        } catch {
            $output.AppendText("[-] robots.txt not found`r`n")
        }

    } catch {
        $output.AppendText("Error connecting to target`r`n")
    }
})

$form.Controls.Add($button)

# Run GUI
$form.ShowDialog()
