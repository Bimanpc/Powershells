# Load the required assembly
Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Task Manager"
$form.Size = New-Object System.Drawing.Size(600,400)

# Create a DataGridView to display network tasks
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Size = New-Object System.Drawing.Size(580,300)
$dataGridView.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($dataGridView)

# Create a button to refresh the network tasks
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh"
$refreshButton.Location = New-Object System.Drawing.Point(10,320)
$form.Controls.Add($refreshButton)

# Function to get network tasks
function Get-NetworkTasks {
    # Example: Get network connections
    Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State
}

# Refresh button click event
$refreshButton.Add_Click({
    $dataGridView.DataSource = Get-NetworkTasks()
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
