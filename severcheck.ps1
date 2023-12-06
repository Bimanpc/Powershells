# Load the WinForms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Server Status Checker"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true

# Create label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(200,20)
$label.Text = "Enter server names (comma-separated):"
$form.Controls.Add($label)

# Create input textbox
$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Location = New-Object System.Drawing.Point(10,40)
$textbox.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textbox)

# Create result textbox
$resultTextBox = New-Object System.Windows.Forms.TextBox
$resultTextBox.Location = New-Object System.Drawing.Point(10,70)
$resultTextBox.Size = New-Object System.Drawing.Size(380,80)
$resultTextBox.Multiline = $true
$resultTextBox.ScrollBars = "Vertical"
$resultTextBox.ReadOnly = $true
$form.Controls.Add($resultTextBox)

# Create check status button
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(220,40)
$button.Size = New-Object System.Drawing.Size(150,20)
$button.Text = "Check Status"
$button.Add_Click({
    # Get server names from the textbox
    $servers = $textbox.Text -split ','

    # Check server status
    $statusResults = @()
    foreach ($server in $servers) {
        $status = Test-Connection -ComputerName $server -Count 2 -ErrorAction SilentlyContinue
        $statusResults += "$server: $($status.Status)"
    }

    # Display results in the result textbox
    $resultTextBox.Text = $statusResults -join "`r`n"
})
$form.Controls.Add($button)

# Display the form
[Windows.Forms.Application]::Run($form)
