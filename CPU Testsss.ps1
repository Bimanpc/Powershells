Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = "CPU Stress Test"
$form.Width = 300
$form.Height = 150
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

# Create a label
$label = New-Object Windows.Forms.Label
$label.Location = New-Object Drawing.Point(10, 20)
$label.Size = New-Object Drawing.Size(280, 20)
$label.Text = "Choose the CPU stress test duration (in secs):"
$form.Controls.Add($label)

# Create a numeric up-down control
$numericUpDown = New-Object Windows.Forms.NumericUpDown
$numericUpDown.Location = New-Object Drawing.Point(10, 50)
$numericUpDown.Size = New-Object Drawing.Size(100, 20)
$numericUpDown.Minimum = 1
$numericUpDown.Maximum = 3600
$numericUpDown.Value = 60
$form.Controls.Add($numericUpDown)

# Create a start button
$button = New-Object Windows.Forms.Button
$button.Location = New-Object Drawing.Point(120, 50)
$button.Size = New-Object Drawing.Size(75, 23)
$button.Text = "Start Test"
$button.Add_Click({
    $duration = $numericUpDown.Value
    Start-CpuStressTest -Duration $duration
})
$form.Controls.Add($button)

# Function to start the CPU stress test
function Start-CpuStressTest {
    param (
        [int]$Duration
    )
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)

    while (Get-Date -lt $endTime) {
        # This loop will simulate CPU load
    }

    [System.Windows.Forms.MessageBox]::Show("CPU Stress Test completed!")
}

# Show the form
$form.ShowDialog()

