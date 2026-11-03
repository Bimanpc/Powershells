# GPS Pet Tracker GUI (PowerShell + Windows Forms)
# Simulated GPS tracker for pets
# Save as: PetTracker.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Pet GPS Tracker"
$form.Size = New-Object System.Drawing.Size(500,350)
$form.StartPosition = "CenterScreen"

$title = New-Object System.Windows.Forms.Label
$title.Text = "Pet GPS Tracker"
$title.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(150,10)
$title.AutoSize = $true
$form.Controls.Add($title)

$petLabel = New-Object System.Windows.Forms.Label
$petLabel.Text = "Pet Name:"
$petLabel.Location = New-Object System.Drawing.Point(20,60)
$form.Controls.Add($petLabel)

$petText = New-Object System.Windows.Forms.TextBox
$petText.Location = New-Object System.Drawing.Point(100,58)
$petText.Width = 150
$form.Controls.Add($petText)

$gpsGroup = New-Object System.Windows.Forms.GroupBox
$gpsGroup.Text = "GPS Information"
$gpsGroup.Location = New-Object System.Drawing.Point(20,100)
$gpsGroup.Size = New-Object System.Drawing.Size(440,120)
$form.Controls.Add($gpsGroup)

$latLabel = New-Object System.Windows.Forms.Label
$latLabel.Location = New-Object System.Drawing.Point(20,30)
$latLabel.AutoSize = $true
$latLabel.Text = "Latitude: N/A"
$gpsGroup.Controls.Add($latLabel)

$lonLabel = New-Object System.Windows.Forms.Label
$lonLabel.Location = New-Object System.Drawing.Point(20,60)
$lonLabel.AutoSize = $true
$lonLabel.Text = "Longitude: N/A"
$gpsGroup.Controls.Add($lonLabel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20,90)
$statusLabel.AutoSize = $true
$statusLabel.Text = "Status: Offline"
$gpsGroup.Controls.Add($statusLabel)

$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Text = "Start Tracking"
$startBtn.Location = New-Object System.Drawing.Point(50,250)
$startBtn.Size = New-Object System.Drawing.Size(120,35)
$form.Controls.Add($startBtn)

$stopBtn = New-Object System.Windows.Forms.Button
$stopBtn.Text = "Stop Tracking"
$stopBtn.Location = New-Object System.Drawing.Point(200,250)
$stopBtn.Size = New-Object System.Drawing.Size(120,35)
$form.Controls.Add($stopBtn)

$mapBtn = New-Object System.Windows.Forms.Button
$mapBtn.Text = "Open Map"
$mapBtn.Location = New-Object System.Drawing.Point(350,250)
$mapBtn.Size = New-Object System.Drawing.Size(100,35)
$form.Controls.Add($mapBtn)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000

$global:CurrentLat = 37.9838
$global:CurrentLon = 23.7275

$timer.Add_Tick({

    $global:CurrentLat += (Get-Random -Minimum -0.0010 -Maximum 0.0010)
    $global:CurrentLon += (Get-Random -Minimum -0.0010 -Maximum 0.0010)

    $latLabel.Text = "Latitude: " + [math]::Round($global:CurrentLat,6)
    $lonLabel.Text = "Longitude: " + [math]::Round($global:CurrentLon,6)
    $statusLabel.Text = "Status: Tracking"

})

$startBtn.Add_Click({
    $timer.Start()
    $statusLabel.Text = "Status: Tracking Started"
})

$stopBtn.Add_Click({
    $timer.Stop()
    $xt = "Status: Tracking Stopped"
})

$mapBtn.Add_Click({

    $url = "https://www.google.com/maps?q=$global:CurrentLat,$global:CurrentLon"
    Start-Process $url

})

[void]$form.ShowDialog()
