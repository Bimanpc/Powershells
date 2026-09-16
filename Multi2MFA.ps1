Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Account Manager (Mockup)"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# Add a Label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(360, 20)
$label.Text = "Account List (Simulation Only)"
$form.Controls.Add($label)

# Add a DataGridView to simulate a list
$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Location = New-Object System.Drawing.Point(10, 50)
$dataGrid.Size = New-Object System.Drawing.Size(360, 150)
$dataGrid.ReadOnly = $true
$dataGrid.AllowUserToAddRows = $false

# Define Columns
$dataGrid.Columns.Add("Service", "Service Name")
$dataGrid.Columns.Add("User", "Username")
$dataGrid.Columns.Add("Status", "Status")

# Add Mock Data
$row1 = $dataGrid.Rows.Add("Google", "user@example.com", "Active")
$row2 = $dataGrid.Rows.Add("GitHub", "dev_user", "Active")
$row3 = $dataGrid.Rows.Add("Microsoft", "admin@corp.com", "Pending")

$form.Controls.Add($dataGrid)

# Add a Button
$btn = New-Object System.Windows.Forms.Button
$btn.Location = New-Object System.Drawing.Point(140, 220)
$btn.Size = New-Object System.Drawing.Size(100, 30)
$btn.Text = "Refresh"
$btn.BackColor = [System.Drawing.Color]::LightBlue
$btn.Add_Click({
    # Simulation logic only
    [System.Windows.Forms.MessageBox]::Show("Data refreshed (Mockup)", "Info", "OK", "Information")
})
$form.Controls.Add($btn)

# Show the form
$form.ShowDialog()
