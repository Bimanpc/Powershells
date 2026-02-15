# YouTube Desktop Player - Simple WinForms GUI
# Save as: YouTubePlayer.ps1 and run with: powershell -ExecutionPolicy Bypass -File .\YouTubePlayer.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Form
$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "YouTube Desktop Player"
$form.StartPosition    = "CenterScreen"
$form.Size             = New-Object System.Drawing.Size(1024, 640)
$form.MinimumSize      = New-Object System.Drawing.Size(800, 500)

# URL label
$label                 = New-Object System.Windows.Forms.Label
$label.Text            = "YouTube URL:"
$label.AutoSize        = $true
$label.Location        = New-Object System.Drawing.Point(10, 12)

# URL textbox
$textBox               = New-Object System.Windows.Forms.TextBox
$textBox.Location      = New-Object System.Drawing.Point(90, 8)
$textBox.Width         = 750
$textBox.Anchor        = "Top,Left,Right"
$textBox.Text          = "https://www.youtube.com"

# Play button
$button                = New-Object System.Windows.Forms.Button
$button.Text           = "Play"
$button.Width          = 80
$button.Height         = 24
$button.Location       = New-Object System.Drawing.Point(850, 6)
$button.Anchor         = "Top,Right"

# WebBrowser (IE engine; works best if IE mode still available)
$browser               = New-Object System.Windows.Forms.WebBrowser
$browser.Location      = New-Object System.Drawing.Point(10, 40)
$browser.Size          = New-Object System.Drawing.Size(990, 550)
$browser.Anchor        = "Top,Bottom,Left,Right"
$browser.ScriptErrorsSuppressed = $true

# Initial page
$browser.Navigate("https://www.youtube.com")

# Button click: navigate to URL
$button.Add_Click({
    $url = $textBox.Text.Trim()
    if (-not $url) { return }
    if ($url -notmatch '^https?://') {
        $url = "https://$url"
    }
    try {
        $browser.Navigate($url)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to navigate to URL.`n$($_.Exception.Message)", "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

# Enter key in textbox triggers Play
$textBox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $button.PerformClick()
        $e.SuppressKeyPress = $true
    }
})

# Add controls
$form.Controls.Add($label)
$form.Controls.Add($textBox)
$form.Controls.Add($button)
$form.Controls.Add($browser)

# Run
[void]$form.ShowDialog()
