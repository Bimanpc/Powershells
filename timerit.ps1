Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Internet Time Timer"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Create a label to display the time
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(280, 20)
$label.Text = "Time: 00:00:00"
$form.Controls.Add($label)

# Create a start button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(10, 50)
$startButton.Size = New-Object System.Drawing.Size(80, 30)
$startButton.Text = "Start"
$startButton.Add_Click({
    $script:sw = [System.Diagnostics.Stopwatch]::StartNew()
    $script:timer = New-Object System.Windows.Forms.Timer
    $script:timer.Interval = 1000
    $script:timer.Add_Tick({
        $label.Text = "Time: " + $sw.Elapsed.ToString("hh\:mm\:ss")
    })
    $script:timer.Start()
})
$form.Controls.Add($startButton)

# Create a stop button
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Location = New-Object System.Drawing.Point(100, 50)
$stopButton.Size = New-Object System.Drawing.Size(80, 30)
$stopButton.Text = "Stop"
$stopButton.Add_Click({
    if ($script:timer) {
        $script:timer.Stop()
    }
    if ($script:sw) {
        $script:sw.Stop()
    }
})
$form.Controls.Add($stopButton)

# Create a reset button
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Location = New-Object System.Drawing.Point(190, 50)
$resetButton.Size = New-Object System.Drawing.Size(80, 30)
$resetButton.Text = "Reset"
$resetButton.Add_Click({
    if ($script:timer) {
        $script:timer.Stop()
    }
    if ($script:sw) {
        $script:sw.Reset()
    }
    $label.Text = "Time: 00:00:00"
})
$form.Controls.Add($resetButton)

# Show the form
$form.ShowDialog()
