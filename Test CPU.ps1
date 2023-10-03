Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CPU Test"
$form.Width = 300
$form.Height = 150

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Click the button to start the CPU test."
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

# Create a button to start the CPU test
$button = New-Object System.Windows.Forms.Button
$button.Text = "Start CPU Test"
$button.Location = New-Object System.Drawing.Point(10, 50)
$button.Width = 120
$button.Add_Click({
    Start-CpuTest
})
$form.Controls.Add($button)

# Function to simulate a CPU test
function Start-CpuTest {
    # Simulate a CPU-intensive operation
    for ($i = 0; $i -lt 1000000; $i++) {
        $null = $i * $i
    }
    [System.Windows.Forms.MessageBox]::Show("CPU test completed.")
}

# Show the form
$form.ShowDialog()
