# Load Windows Forms Assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WiFi Speed Test"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Add Labels for download and upload speed
$downloadLabel = New-Object System.Windows.Forms.Label
$downloadLabel.Text = "Download Speed: "
$downloadLabel.Location = New-Object System.Drawing.Point(50, 100)
$downloadLabel.AutoSize = $true
$form.Controls.Add($downloadLabel)

$uploadLabel = New-Object System.Windows.Forms.Label
$uploadLabel.Text = "Upload Speed: "
$uploadLabel.Location = New-Object System.Drawing.Point(50, 150)
$uploadLabel.AutoSize = $true
$form.Controls.Add($uploadLabel)

# Add a button to start the test
$button = New-Object System.Windows.Forms.Button
$button.Text = "Run Speed Test"
$button.Location = New-Object System.Drawing.Point(50, 50)
$button.AutoSize = $true

# Button click event
$button.Add_Click({
    # Run speedtest-cli and capture the output
    $result = speedtest --format=json | ConvertFrom-Json

    # Update labels with the results
    if ($result) {
        $downloadLabel.Text = "Download Speed: " + [math]::round($result.download.bandwidth * 0.000008, 2) + " Mbps"
        $uploadLabel.Text = "Upload Speed: " + [math]::round($result.upload.bandwidth * 0.000008, 2) + " Mbps"
    } else {
        $downloadLabel.Text = "Download Speed: Error"
        $uploadLabel.Text = "Upload Speed: Error"
    }
})

$form.Controls.Add($button)

# Run the form
$form.Topmost = $true
[void]$form.ShowDialog()
