Add-Type -AssemblyName System.Windows.Forms

# Create a Form
$form = New-Object Windows.Forms.Form
$form.Text = "SSD Temperature Monitor"
$form.Size = New-Object Drawing.Size(400, 300)

# Create a ListView control to display the temperature data
$listView = New-Object Windows.Forms.ListView
$listView.Location = New-Object Drawing.Point(10, 10)
$listView.Size = New-Object Drawing.Size(360, 200)
$listView.View = [System.Windows.Forms.View]::Details

# Add columns to the ListView
$listView.Columns.Add("Drive", 100)
$listView.Columns.Add("Temperature (°C)", 150)

# Add the ListView to the form
$form.Controls.Add($listView)

# Button to refresh the data
$button = New-Object Windows.Forms.Button
$button.Text = "Refresh"
$button.Location = New-Object Drawing.Point(10, 220)
$button.Add_Click({
    $listView.Items.Clear()
    $diskInfo = & "C:\Path\to\Get-SSDTemperature.ps1"
    foreach ($disk in $diskInfo) {
        $item = $listView.Items.Add($disk.Drive)
        $item.SubItems.Add($disk.Temperature)
    }
})
$form.Controls.Add($button)

# Show the form
$form.ShowDialog()
