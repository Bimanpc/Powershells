Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# WHOIS function (simple, no external tools)
function Invoke-Whois {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query
    )

    if ([string]::IsNullOrWhiteSpace($Query)) {
        return "No query provided."
    }

    # Basic normalization
    $q = $Query.Trim()

    # Default WHOIS server (works for most gTLDs)
    $whoisServer = "whois.iana.org"

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($whoisServer, 43)

        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.NewLine = "`r`n"
        $writer.WriteLine($q)
        $writer.Flush()

        $reader = New-Object System.IO.StreamReader($stream)
        $response = $reader.ReadToEnd()

        $reader.Close()
        $writer.Close()
        $client.Close()

        if ([string]::IsNullOrWhiteSpace($response)) {
            return "No response from WHOIS server."
        }

        return $response
    }
    catch {
        return "Error during WHOIS query:`r`n$($_.Exception.Message)"
    }
}

# Form
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "WHOIS Lookup"
$form.StartPosition = "CenterScreen"
$form.Size          = New-Object System.Drawing.Size(800, 600)
$form.Topmost       = $false

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Domain / IP:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 15)

# TextBox for query
$textBoxQuery = New-Object System.Windows.Forms.TextBox
$textBoxQuery.Location = New-Object System.Drawing.Point(100, 10)
$textBoxQuery.Size = New-Object System.Drawing.Size(500, 20)
$textBoxQuery.Anchor = "Top,Left,Right"

# Button
$buttonLookup = New-Object System.Windows.Forms.Button
$buttonLookup.Text = "Lookup"
$buttonLookup.Location = New-Object System.Drawing.Point(620, 8)
$buttonLookup.Size = New-Object System.Drawing.Size(80, 25)
$buttonLookup.Anchor = "Top,Right"

# Clear button
$buttonClear = New-Object System.Windows.Forms.Button
$buttonClear.Text = "Clear"
$buttonClear.Location = New-Object System.Drawing.Point(710, 8)
$buttonClear.Size = New-Object System.Drawing.Size(60, 25)
$buttonClear.Anchor = "Top,Right"

# Output TextBox (multiline)
$textBoxOutput = New-Object System.Windows.Forms.TextBox
$textBoxOutput.Location = New-Object System.Drawing.Point(10, 45)
$textBoxOutput.Size = New-Object System.Drawing.Size(760, 500)
$textBoxOutput.Multiline = $true
$textBoxOutput.ScrollBars = "Both"
$textBoxOutput.ReadOnly = $true
$textBoxOutput.Font = New-Object System.Drawing.Font("Consolas", 9)
$textBoxOutput.Anchor = "Top,Bottom,Left,Right"
$textBoxOutput.WordWrap = $false

# Status strip
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusStrip.Items.Add($statusLabel)

# Event: Lookup
$buttonLookup.Add_Click({
    $query = $textBoxQuery.Text
    if ([string]::IsNullOrWhiteSpace($query)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a domain or IP.", "WHOIS", "OK", "Information") | Out-Null
        return
    }

    $statusLabel.Text = "Querying..."
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $textBoxOutput.Text = ""

    # Run WHOIS in a job-like way but still simple (no background runspace)
    try {
        $result = Invoke-Whois -Query $query
        $textBoxOutput.Text = $result
        $statusLabel.Text = "Done"
    }
    finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})

# Event: Clear
$buttonClear.Add_Click({
    $textBoxQuery.Clear()
    $textBoxOutput.Clear()
    $statusLabel.Text = "Ready"
})

# Enter key triggers lookup
$textBoxQuery.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $buttonLookup.PerformClick()
        $e.SuppressKeyPress = $true
    }
})

# Add controls
$form.Controls.Add($label)
$form.Controls.Add($textBoxQuery)
$form.Controls.Add($buttonLookup)
$form.Controls.Add($buttonClear)
$form.Controls.Add($textBoxOutput)
$form.Controls.Add($statusStrip)

# Run
[void]$form.ShowDialog()
