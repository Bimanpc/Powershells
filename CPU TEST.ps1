Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CPU Test"
$form.Width = 300
$form.Height = 200

# Create labels and buttons
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(280, 40)
$label.Text = "Click the 'Run Test' button to perform a CPU test."
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($label)

$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(100, 100)
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Text = "Run Test"
$form.Controls.Add($button)

# Event handler for button click
$button.Add_Click({
    $result = Measure-Command {
        # Perform a CPU-intensive operation (e.g., Fibonacci calculation)
        $fibonacci = {
            param($n)
            if ($n -le 1) { return $n }
            return (&$fibonacci ($n - 1)) + (&$fibonacci ($n - 2))
        }

        $testValue = 35  # Change this value based on desired test intensity
        $fibonacci.Invoke($testValue)
    }

    [System.Windows.Forms.MessageBox]::Show("CPU test completed.`r`nElapsed time: $($result.TotalMilliseconds) milliseconds.")
})

# Show the form
$form.ShowDialog()
