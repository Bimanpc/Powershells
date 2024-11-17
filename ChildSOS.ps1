# Load the necessary assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SOS Tracker for Child"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Add a label for instructions
$label = New-Object System.Windows.Forms.Label
$label.Text = "Click the button to send an SOS signal."
$label.Size = New-Object System.Drawing.Size(300, 20)
$label.Location = New-Object System.Drawing.Point(50, 20)
$form.Controls.Add($label)

# Add a list box to display recent alerts
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(300, 100)
$listBox.Location = New-Object System.Drawing.Point(50, 50)
$form.Controls.Add($listBox)

# Add an SOS button
$sosButton = New-Object System.Windows.Forms.Button
$sosButton.Text = "Send SOS"
$sosButton.Size = New-Object System.Drawing.Size(100, 30)
$sosButton.Location = New-Object System.Drawing.Point(150, 160)

# Define the SOS button click event
$sosButton.Add_Click({
    # Log the SOS alert in the list box
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $listBox.Items.Add("SOS sent at $timestamp")
    
    # Trigger SOS functionality (e.g., send notification or log to a server)
    # Place additional code here to send notifications, such as using APIs
    
    [System.Windows.Forms.MessageBox]::Show("SOS alert sent!", "Alert", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($sosButton)

# Add an Exit button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(100, 30)
$exitButton.Location = New-Object System.Drawing.Point(150, 200)

# Define the Exit button click event
$exitButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($exitButton)

# Run the form
[void]$form.ShowDialog()
