# Import Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Create the Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Driver List App"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Create a Button to fetch drivers
$fetchButton = New-Object System.Windows.Forms.Button
$fetchButton.Text = "Fetch Drivers"
$fetchButton.Size = New-Object System.Drawing.Size(100, 30)
$fetchButton.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($fetchButton)

# Create a DataGridView to display the drivers
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Size = New-Object System.Drawing.Size(560, 300)
$dataGridView.Location = New-Object System.Drawing.Point(10, 50)
$dataGridView.ReadOnly = $true
$dataGridView.AllowUserToAddRows = $false
$dataGridView.AutoSizeColumnsMode = "Fill"
$form.Controls.Add($dataGridView)

# Event handler for fetching drivers
$fetchButton.Add_Click({
    # Get the list of drivers
    $drivers = Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer

    # Convert the results to a DataTable for display
    $dataTable = New-Object System.Data.DataTable
    $dataTable.Columns.Add("Device Name") | Out-Null
    $dataTable.Columns.Add("Driver Version") | Out-Null
    $dataTable.Columns.Add("Manufacturer") | Out-Null

    foreach ($driver in $drivers) {
        $dataTable.Rows.Add($driver.DeviceName, $driver.DriverVersion, $driver.Manufacturer) | Out-Null
    }

    # Bind the DataTable to the DataGridView
    $dataGridView.DataSource = $dataTable
})

# Run the Form
[void]$form.ShowDialog()
