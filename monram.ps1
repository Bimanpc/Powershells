# Create a Form
$form = New-Object Windows.Forms.Form
$form.Text = "RAM Monitor"
$form.Size = New-Object Drawing.Size @(300,150)

# Create a Label to display RAM usage
$label = New-Object Windows.Forms.Label
$label.Location = New-Object Drawing.Point @(10,30)
$label.Size = New-Object Drawing.Size @(280,30)
$form.Controls.Add($label)

# Create a Timer to update RAM usage every second
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $ramUsage = Get-WmiObject Win32_OperatingSystem | ForEach-Object { $_.FreePhysicalMemory / $_.TotalVisibleMemorySize * 100 }
    $label.Text = "RAM Usage: $($ramUsage.ToString("F2"))%"
})
$form.Controls.Add($timer)
$timer.Start()

# Show the Form
$form.ShowDialog()
