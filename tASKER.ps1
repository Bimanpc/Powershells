# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Task Manager AI "
$form.Size = New-Object System.Drawing.Size(600,400)

# Create a list view
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10,10)
$listView.Size = New-Object System.Drawing.Size(580,300)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true

# Add columns to the list view
$listView.Columns.Add("Process ID", 80)
$listView.Columns.Add("Name", 200)
$listView.Columns.Add("CPU", 80)
$listView.Columns.Add("Memory (MB)", 100)

# Get the list of processes
$processes = Get-Process | Select-Object Id, ProcessName, CPU, PM

# Populate the list view with processes
foreach ($process in $processes) {
    $item = New-Object System.Windows.Forms.ListViewItem($process.Id)
    $item.SubItems.Add($process.ProcessName)
    $item.SubItems.Add($process.CPU)
    $item.SubItems.Add($process.PM)
    $listView.Items.Add($item)
}

# Add controls to the form
$form.Controls.Add($listView)

# Display the form
$form.Add_Shown({$form.Activate()})
[Windows.Forms.Application]::Run($form)
