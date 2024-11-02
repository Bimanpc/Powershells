Add-Type -AssemblyName System.Windows.Forms

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "DNS Data Viewer"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Input Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Domain:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

# Input TextBox
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(100, 15)
$textBox.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($textBox)

# Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Fetch DNS Data"
$button.Location = New-Object System.Drawing.Point(420, 12)
$form.Controls.Add($button)

# DataGridView
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10, 50)
$dataGridView.Size = New-Object System.Drawing.Size(560, 300)
$dataGridView.AutoSizeColumnsMode = "Fill"
$form.Controls.Add($dataGridView)

# Button Click Event
$button.Add_Click({
    # Clear existing rows
    $dataGridView.Rows.Clear()
    $dataGridView.Columns.Clear()

    # Get the domain from textbox
    $domain = $textBox.Text
    if (![string]::IsNullOrWhiteSpace($domain)) {
        try {
            # Retrieve DNS records
            $dnsRecords = Resolve-DnsName -Name $domain -ErrorAction Stop

            # Add columns
            $dataGridView.Columns.Add("Name", "Name")
            $dataGridView.Columns.Add("QueryType", "Query Type")
            $dataGridView.Columns.Add("TTL", "TTL")
            $dataGridView.Columns.Add("IPAddress", "IP Address")

            # Add DNS record data to DataGridView
            foreach ($record in $dnsRecords) {
                $row = $dataGridView.Rows.Add()
                $dataGridView.Rows[$row].Cells["Name"].Value = $record.Name
                $dataGridView.Rows[$row].Cells["QueryType"].Value = $record.QueryType
                $dataGridView.Rows[$row].Cells["TTL"].Value = $record.Ttl
                $dataGridView.Rows[$row].Cells["IPAddress"].Value = $record.IPAddress
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error fetching DNS data: $_")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter a domain.")
    }
})

# Run the form
[void]$form.ShowDialog()
